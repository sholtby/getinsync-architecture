# CSDM Crawl Validation Scripts
## GlideRecord scripts to verify Crawl readiness beyond sn_getwell

> Paste these into **System Definition → Scripts - Background** (requires admin role).
> Each script outputs results to the system log. Run them after loading data to find gaps.

---

## Script 1: Business Applications missing required fields

Checks every active Business Application for blank required Crawl fields.

```javascript
// CSDM Crawl Validator — Business Application Required Fields
// Paste into Scripts - Background and run
(function() {
    var gr = new GlideRecord('cmdb_ci_business_app');
    gr.addActiveQuery();
    gr.query();

    var total = 0;
    var issues = [];
    var fieldChecks = [
        { field: 'owned_by',           label: 'Business Owner' },
        { field: 'managed_by',         label: 'IT Application Owner' },
        { field: 'managed_by_group',   label: 'Managed by Group' },
        { field: 'busines_criticality', label: 'Business Criticality' },
        { field: 'install_status',     label: 'Install Status' },
        { field: 'operational_status', label: 'Operational Status' }
    ];

    while (gr.next()) {
        total++;
        var missing = [];
        for (var i = 0; i < fieldChecks.length; i++) {
            if (gr.getValue(fieldChecks[i].field) === null ||
                gr.getValue(fieldChecks[i].field) === '') {
                missing.push(fieldChecks[i].label);
            }
        }
        if (missing.length > 0) {
            issues.push(gr.getValue('name') + ' — missing: ' + missing.join(', '));
        }
    }

    gs.info('=== CSDM CRAWL: Business Application Field Completeness ===');
    gs.info('Total active Business Applications: ' + total);
    gs.info('Applications with missing fields: ' + issues.length);
    gs.info('Completeness: ' + Math.round((total - issues.length) / total * 100) + '%');
    gs.info('');
    if (issues.length > 0) {
        gs.info('--- Applications with gaps ---');
        for (var j = 0; j < issues.length; j++) {
            gs.info(issues[j]);
        }
    }
})();
```

---

## Script 2: Business Applications without Application Service relationships

This is what sn_getwell checks — but this script gives you the specific list of offenders.

```javascript
// CSDM Crawl Validator — Business App ↔ Application Service Relationships
(function() {
    var gr = new GlideRecord('cmdb_ci_business_app');
    gr.addActiveQuery();
    gr.query();

    var total = 0;
    var noRelationship = [];
    var wrongType = [];

    // Get the correct relationship type sys_id
    var relType = new GlideRecord('cmdb_rel_type');
    relType.addQuery('name', 'Consumes::Consumed by');
    relType.query();
    var consumesSysId = relType.next() ? relType.getUniqueValue() : null;

    if (!consumesSysId) {
        gs.info('ERROR: Could not find "Consumes::Consumed by" relationship type.');
        return;
    }

    while (gr.next()) {
        total++;
        var bizAppSysId = gr.getUniqueValue();

        // Check for ANY relationship to an Application Service
        var rel = new GlideRecord('cmdb_rel_ci');
        rel.addQuery('parent', bizAppSysId);
        rel.addQuery('child.sys_class_name', 'INSTANCEOF', 'cmdb_ci_service_auto');
        rel.query();

        if (!rel.hasNext()) {
            noRelationship.push(gr.getValue('name'));
        } else {
            // Check if relationship type is correct
            var hasCorrectType = false;
            while (rel.next()) {
                if (rel.getValue('type') === consumesSysId) {
                    hasCorrectType = true;
                    break;
                }
            }
            if (!hasCorrectType) {
                wrongType.push(gr.getValue('name'));
            }
        }
    }

    gs.info('=== CSDM CRAWL: Business App → Application Service Relationships ===');
    gs.info('Total active Business Applications: ' + total);
    gs.info('Missing Application Service: ' + noRelationship.length);
    gs.info('Wrong relationship type: ' + wrongType.length);
    gs.info('Fully compliant: ' + (total - noRelationship.length - wrongType.length));
    gs.info('');
    if (noRelationship.length > 0) {
        gs.info('--- No Application Service relationship ---');
        for (var i = 0; i < noRelationship.length; i++) {
            gs.info(noRelationship[i]);
        }
    }
    if (wrongType.length > 0) {
        gs.info('--- Wrong relationship type (not Consumes::Consumed by) ---');
        for (var j = 0; j < wrongType.length; j++) {
            gs.info(wrongType[j]);
        }
    }
})();
```

---

## Script 3: Application Services missing required fields

```javascript
// CSDM Crawl Validator — Application Service Required Fields
(function() {
    var gr = new GlideRecord('cmdb_ci_service_auto');
    gr.addActiveQuery();
    gr.query();

    var total = 0;
    var issues = [];
    var fieldChecks = [
        { field: 'owned_by',         label: 'Owned By' },
        { field: 'managed_by_group', label: 'Managed By Group' },
        { field: 'support_group',    label: 'Support Group' },
        { field: 'change_control',   label: 'Change Group' },
        { field: 'environment',      label: 'Environment' },
        { field: 'busines_criticality', label: 'Business Criticality' }
    ];

    while (gr.next()) {
        total++;
        var missing = [];
        for (var i = 0; i < fieldChecks.length; i++) {
            if (gr.getValue(fieldChecks[i].field) === null ||
                gr.getValue(fieldChecks[i].field) === '') {
                missing.push(fieldChecks[i].label);
            }
        }
        if (missing.length > 0) {
            issues.push(gr.getValue('name') + ' — missing: ' + missing.join(', '));
        }
    }

    gs.info('=== CSDM CRAWL: Application Service Field Completeness ===');
    gs.info('Total active Application Services: ' + total);
    gs.info('Services with missing fields: ' + issues.length);
    gs.info('Completeness: ' + Math.round((total - issues.length) / total * 100) + '%');
    gs.info('');
    if (issues.length > 0) {
        gs.info('--- Application Services with gaps ---');
        for (var j = 0; j < issues.length; j++) {
            gs.info(issues[j]);
        }
    }
})();
```

---

## Script 4: Orphan Application Services (no parent Business Application)

```javascript
// CSDM Crawl Validator — Orphan Application Services
(function() {
    var gr = new GlideRecord('cmdb_ci_service_auto');
    gr.addActiveQuery();
    gr.query();

    var total = 0;
    var orphans = [];

    while (gr.next()) {
        total++;
        var svcSysId = gr.getUniqueValue();

        var rel = new GlideRecord('cmdb_rel_ci');
        rel.addQuery('child', svcSysId);
        rel.addQuery('parent.sys_class_name', 'cmdb_ci_business_app');
        rel.query();

        if (!rel.hasNext()) {
            orphans.push(gr.getValue('name') + ' (' + gr.getValue('sys_class_name') + ')');
        }
    }

    gs.info('=== CSDM CRAWL: Orphan Application Services ===');
    gs.info('Total active Application Services: ' + total);
    gs.info('Orphans (no parent Business Application): ' + orphans.length);
    gs.info('');
    if (orphans.length > 0) {
        for (var i = 0; i < orphans.length; i++) {
            gs.info(orphans[i]);
        }
    }
})();
```

---

## Script 5: Combined Crawl readiness scorecard

```javascript
// CSDM Crawl Validator — Combined Scorecard
(function() {
    gs.info('========================================');
    gs.info('  CSDM CRAWL READINESS SCORECARD');
    gs.info('========================================');
    gs.info('');

    // Count Business Applications
    var ba = new GlideAggregate('cmdb_ci_business_app');
    ba.addActiveQuery();
    ba.addAggregate('COUNT');
    ba.query();
    var baCount = ba.next() ? parseInt(ba.getAggregate('COUNT')) : 0;

    // Count Application Services
    var svc = new GlideAggregate('cmdb_ci_service_auto');
    svc.addActiveQuery();
    svc.addAggregate('COUNT');
    svc.query();
    var svcCount = svc.next() ? parseInt(svc.getAggregate('COUNT')) : 0;

    // Ratio
    var ratio = baCount > 0 ? (svcCount / baCount).toFixed(1) : 0;

    gs.info('Business Applications (active): ' + baCount);
    gs.info('Application Services (active):  ' + svcCount);
    gs.info('Ratio (Services per App):       ' + ratio);
    gs.info('');

    // Check if ratio is healthy
    if (ratio < 1) {
        gs.info('⚠ WARNING: Fewer Application Services than Business Applications.');
        gs.info('  Every Business App needs at least one Application Service.');
    } else if (ratio > 5) {
        gs.info('⚠ NOTE: High ratio — verify Application Services are meaningful,');
        gs.info('  not auto-generated stubs.');
    } else {
        gs.info('✓ Ratio looks healthy.');
    }

    gs.info('');
    gs.info('Run the individual validation scripts for detailed gap analysis.');
    gs.info('========================================');
})();
```

---

## When to run these scripts

| Script | When | Expected result at Crawl |
|--------|------|------------------------|
| Script 1 (BA fields) | After every import | 0 applications with missing required fields |
| Script 2 (Relationships) | After creating Application Services | 0 missing, 0 wrong type |
| Script 3 (AS fields) | After every import | 0 services with missing required fields |
| Script 4 (Orphans) | Weekly | 0 orphan Application Services |
| Script 5 (Scorecard) | Weekly | Ratio ≥ 1.0, all counts healthy |

---

*These scripts check what sn_getwell doesn't. For continuous monitoring and automated
data quality governance across 50+ applications, see GetInSync NextGen at getinsync.ca.*
