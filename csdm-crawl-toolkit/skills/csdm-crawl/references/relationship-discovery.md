# CMDB Relationship Discovery Scripts
## Understand your as-is relationship landscape before building the to-be

> Before you can define proper relationship governance, you need to know what
> currently exists. These scripts produce a complete inventory of every CI
> relationship in your ServiceNow instance — which types are in use, between
> which CI classes, and where the gaps are.

---

## Quick Assessment (3 scripts, ~2 minutes)

Run these first for a high-level picture. Output goes to the system log.
Run via **System Definition > Scripts - Background** (admin role required).

### Script 1: Relationship Types in Active Use

Shows every relationship type that has actual records in `cmdb_rel_ci`,
sorted by volume (most-used first).

```javascript
(function() {
    var ga = new GlideAggregate('cmdb_rel_ci');
    ga.addAggregate('COUNT');
    ga.groupBy('type');
    ga.orderByAggregate('COUNT', 'DESC');
    ga.query();

    gs.info('=== Relationship Types in Active Use ===');
    gs.info('Type Name | Count');
    gs.info('---------|------');
    var total = 0;
    var typeCount = 0;
    while (ga.next()) {
        var count = parseInt(ga.getAggregate('COUNT'));
        total += count;
        typeCount++;
        var typeName = ga.type.getDisplayValue();
        gs.info(typeName + ' | ' + count);
    }
    gs.info('---------|------');
    gs.info('Total: ' + total + ' relationships across '
        + typeCount + ' types');
})();
```

**What to look for:** Which types dominate? Are there custom relationship types
(not OOTB)? Is "Sends data to::Receives data from" in use (indicates someone
has been modeling integrations)?

---

### Script 2: CI Class Pairs by Relationship Type

For each relationship type in use, shows which parent CI class connects to
which child CI class, with counts. This reveals structural patterns — and
anti-patterns.

```javascript
(function() {
    var ga = new GlideAggregate('cmdb_rel_ci');
    ga.addAggregate('COUNT');
    ga.groupBy('type');
    ga.groupBy('parent.sys_class_name');
    ga.groupBy('child.sys_class_name');
    ga.orderByAggregate('COUNT', 'DESC');
    ga.query();

    gs.info('=== CI Class Pairs by Relationship Type ===');
    gs.info('Rel Type | Parent Class | Child Class | Count');
    gs.info('---------|-------------|------------|------');
    while (ga.next()) {
        gs.info(
            ga.type.getDisplayValue() + ' | ' +
            ga.parent.sys_class_name.getDisplayValue() + ' | ' +
            ga.child.sys_class_name.getDisplayValue() + ' | ' +
            ga.getAggregate('COUNT')
        );
    }
})();
```

**What to look for:** Are relationships between the correct CI classes? For
example, "Depends on::Used by" should be Application Service → Infrastructure,
not Application → Application. "Consumes::Consumed by" should be Business App
→ Application Service. Anything connecting two Business Applications directly
is likely wrong.

---

### Script 3: Orphan CIs and Relationship Density

For the four CI classes relevant to CSDM Crawl/Walk, counts total CIs, CIs
with at least one relationship, and CIs with zero relationships (orphans).

```javascript
(function() {
    var classes = [
        'cmdb_ci_business_app',
        'cmdb_ci_service_auto',
        'cmdb_ci_appl',
        'cmdb_ci_server'
    ];

    gs.info('=== CI Relationship Density ===');
    gs.info('Class | Total | With Rels | Orphans | % Connected');
    gs.info('------|-------|----------|---------|------------');

    for (var i = 0; i < classes.length; i++) {
        var cls = classes[i];

        var ga = new GlideAggregate(cls);
        ga.addActiveQuery();
        ga.addAggregate('COUNT');
        ga.query();
        var total = ga.next()
            ? parseInt(ga.getAggregate('COUNT')) : 0;

        if (total === 0) {
            gs.info(cls + ' | 0 | 0 | 0 | N/A');
            continue;
        }

        var parents = new GlideAggregate('cmdb_rel_ci');
        parents.addQuery('parent.sys_class_name', cls);
        parents.addAggregate('COUNT', 'DISTINCT', 'parent');
        parents.query();
        var pCount = parents.next()
            ? parseInt(parents.getAggregate(
                'COUNT', 'DISTINCT', 'parent')) : 0;

        var children = new GlideAggregate('cmdb_rel_ci');
        children.addQuery('child.sys_class_name', cls);
        children.addAggregate('COUNT', 'DISTINCT', 'child');
        children.query();
        var cCount = children.next()
            ? parseInt(children.getAggregate(
                'COUNT', 'DISTINCT', 'child')) : 0;

        var connected = Math.min(pCount + cCount, total);
        var orphans = total - connected;
        if (orphans < 0) orphans = 0;
        var pct = Math.round(connected / total * 100);

        gs.info(cls + ' | ' + total + ' | ' + connected +
            ' | ' + orphans + ' | ' + pct + '%');
    }
})();
```

**What to look for:** High orphan counts on `cmdb_ci_appl` suggest Discovery is
populating records nobody has connected to Application Services. Zero records on
`cmdb_ci_business_app` confirms the Crawl gap. `cmdb_ci_server` with high
connectivity means Discovery/Service Mapping is working well for infrastructure.

---

## Full Discovery (4 scripts, CSV output)

These scripts produce CSV-formatted output. Copy from the system log into a text
file, save as `.csv`, and open in Excel for analysis.

**Note:** For instances with 50,000+ relationships, use the filter options shown
in the script comments to scope the export.

### Script 4: Complete Relationship Inventory (CSV)

Exports every CI relationship with type, parent class, parent name, child class,
child name, and sys_id.

```javascript
(function() {
    var gr = new GlideRecord('cmdb_rel_ci');
    // Optional: filter to specific type
    // gr.addQuery('type.name',
    //     'Sends data to::Receives data from');
    gr.setLimit(50000);
    gr.query();

    gs.info('rel_sys_id,rel_type,parent_sys_id,' +
        'parent_class,parent_name,child_sys_id,' +
        'child_class,child_name');

    while (gr.next()) {
        gs.info(
            gr.getUniqueValue() + ',' +
            gr.type.getDisplayValue()
                .replace(/,/g, ';') + ',' +
            gr.parent.getUniqueValue() + ',' +
            gr.parent.sys_class_name
                .getDisplayValue() + ',' +
            gr.parent.name.getDisplayValue()
                .replace(/,/g, ';') + ',' +
            gr.child.getUniqueValue() + ',' +
            gr.child.sys_class_name
                .getDisplayValue() + ',' +
            gr.child.name.getDisplayValue()
                .replace(/,/g, ';')
        );
    }
    gs.info('=== Export complete: ' +
        gr.getRowCount() + ' rows ===');
})();
```

---

### Script 5: Integration / Data Flow Relationships (CSV)

Exports only "Sends data to::Receives data from" and "Exchanges data with"
relationships — the application-to-application data flows.

```javascript
(function() {
    var gr = new GlideRecord('cmdb_rel_ci');
    var qc = gr.addQuery('type.name',
        'Sends data to::Receives data from');
    qc.addOrCondition('type.name',
        'Exchanges data with::Exchanges data with');
    gr.query();

    gs.info('rel_type,sender_class,sender_name,' +
        'receiver_class,receiver_name');

    var count = 0;
    while (gr.next()) {
        count++;
        gs.info(
            gr.type.getDisplayValue()
                .replace(/,/g, ';') + ',' +
            gr.parent.sys_class_name
                .getDisplayValue() + ',' +
            gr.parent.name.getDisplayValue()
                .replace(/,/g, ';') + ',' +
            gr.child.sys_class_name
                .getDisplayValue() + ',' +
            gr.child.name.getDisplayValue()
                .replace(/,/g, ';')
        );
    }
    gs.info('=== Data flow relationships: '
        + count + ' ===');
})();
```

If this returns zero results, no one has modeled application integrations as
CMDB relationships yet. That is common and expected — it means the integration
landscape needs to be built from scratch.

---

### Script 6: Relationship Type Definition Inventory (CSV)

Exports every relationship type defined in `cmdb_rel_type` — both OOTB and
custom — with a flag showing whether each type has actual records.

```javascript
(function() {
    var gr = new GlideRecord('cmdb_rel_type');
    gr.orderBy('name');
    gr.query();

    gs.info('sys_id,name,parent_descriptor,' +
        'child_descriptor,has_records');

    while (gr.next()) {
        var check = new GlideAggregate('cmdb_rel_ci');
        check.addQuery('type', gr.getUniqueValue());
        check.addAggregate('COUNT');
        check.query();
        var used = check.next() &&
            parseInt(check.getAggregate('COUNT')) > 0
            ? 'YES' : 'NO';

        gs.info(
            gr.getUniqueValue() + ',' +
            gr.getValue('name')
                .replace(/,/g, ';') + ',' +
            (gr.getValue('parent_descriptor')
                || '').replace(/,/g, ';') + ',' +
            (gr.getValue('child_descriptor')
                || '').replace(/,/g, ';') + ',' +
            used
        );
    }
})();
```

**What to look for:** Custom relationship types (created by the organization,
not OOTB). Types marked YES that shouldn't be in use. Types marked NO that
should be (like "Consumes::Consumed by" if no Business Applications exist yet).

---

### Script 7: People and Groups on Key CI Classes (CSV)

For Application Services and Applications, exports owner, support group, and
change group fields. Reveals how well people/group governance has been
implemented.

```javascript
(function() {
    gs.info('=== Application Service Ownership ===');
    gs.info('name,owned_by,managed_by_group,' +
        'support_group,change_control,' +
        'environment,operational_status');

    var gr = new GlideRecord('cmdb_ci_service_auto');
    gr.addActiveQuery();
    gr.query();
    var svcCount = 0;
    var svcMissing = 0;
    while (gr.next()) {
        svcCount++;
        var owner = gr.owned_by.getDisplayValue()
            || 'BLANK';
        var mgGroup = gr.managed_by_group
            .getDisplayValue() || 'BLANK';
        var supGroup = gr.support_group
            .getDisplayValue() || 'BLANK';
        var chgGroup = gr.change_control
            .getDisplayValue() || 'BLANK';
        if (owner === 'BLANK' ||
            supGroup === 'BLANK')
            svcMissing++;
        gs.info(
            gr.getValue('name')
                .replace(/,/g, ';') + ',' +
            owner.replace(/,/g, ';') + ',' +
            mgGroup.replace(/,/g, ';') + ',' +
            supGroup.replace(/,/g, ';') + ',' +
            chgGroup.replace(/,/g, ';') + ',' +
            (gr.getValue('environment')
                || 'BLANK') + ',' +
            (gr.getValue('operational_status')
                || 'BLANK')
        );
    }
    gs.info('=== App Services: ' + svcCount +
        ' total, ' + svcMissing +
        ' missing owner or support group ===');

    gs.info('');
    gs.info('=== Application Ownership ===');
    gs.info('name,owned_by,managed_by,' +
        'managed_by_group,operational_status');

    var gr2 = new GlideRecord('cmdb_ci_appl');
    gr2.addActiveQuery();
    gr2.query();
    var appCount = 0;
    var appMissing = 0;
    while (gr2.next()) {
        appCount++;
        var o = gr2.owned_by.getDisplayValue()
            || 'BLANK';
        var m = gr2.managed_by.getDisplayValue()
            || 'BLANK';
        var mg = gr2.managed_by_group
            .getDisplayValue() || 'BLANK';
        if (o === 'BLANK') appMissing++;
        gs.info(
            gr2.getValue('name')
                .replace(/,/g, ';') + ',' +
            o.replace(/,/g, ';') + ',' +
            m.replace(/,/g, ';') + ',' +
            mg.replace(/,/g, ';') + ',' +
            (gr2.getValue('operational_status')
                || 'BLANK')
        );
    }
    gs.info('=== Applications: ' + appCount +
        ' total, ' + appMissing +
        ' missing owner ===');
})();
```

**What to look for:** High BLANK counts on `support_group` means incidents
can't auto-route. BLANK on `owned_by` means nobody is accountable. BLANK on
`change_control` means change risk can't be assessed per service.

---

## Reference: Relationship Type Cheat Sheet

These are the OOTB relationship types most relevant to CSDM. Use this when
reviewing your discovery results.

| Relationship Type | Correct Usage | CSDM Phase |
|---|---|---|
| Consumes::Consumed by | Business App → Application Service | Crawl |
| Depends on::Used by | App Service → Server/DB/Application | Walk |
| Runs on::Runs | Software → Hardware (OS on server) | Walk |
| Contains::Contained by | Rack → Server, Cluster → Node | Walk |
| Hosts::Hosted on | Hypervisor → VM | Walk |
| Sends data to::Receives data from | App Service → App Service (data flow) | Walk+ |
| Exchanges data with::Exchanges data with | Bidirectional data exchange | Walk+ |
| Provides::Provided by | Business Service → BSO | Run |
| Members::Member of | CI → Dynamic CI Group | Walk |
| Managed by::Manages | CI → Management tool | Walk |

## Reference: Common Anti-Patterns

| Anti-Pattern | Why It's Wrong |
|---|---|
| Business App → Business App (any type) | Business Apps are portfolio items, not operational CIs. Data flows go between Application Services. |
| "Depends on" between two Application Services | Usually means "Sends data to" was intended. "Depends on" implies infrastructure dependency. |
| Server → Business App (any type) | Servers relate to Application Services, not Business Apps. Hierarchy: Business App → App Service → Server. |
| Custom types duplicating OOTB | Check for types like "Interfaces with" that duplicate OOTB "Sends data to." |
| Thousands of "Depends on" from a single CI | Usually a Discovery misconfiguration creating over-broad dependency maps. |

---

*These scripts are read-only — they do not modify any data. For organizations
managing 50+ applications, GetInSync NextGen provides continuous relationship
monitoring and CSDM-aligned export. See getinsync.ca.*
