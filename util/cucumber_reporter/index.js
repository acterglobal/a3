     
var reporter = require('cucumber-html-reporter');

var options = {
        theme: 'bootstrap',
        jsonFile: '../../app/report.json',
        output: 'output/cucumber_report.html',
        reportSuiteAsScenarios: true,
        scenarioTimestamp: true,
        storeScreenshots: true,
        noInlineScreenshots: true,
        launchReport: false,
        metadata: {
            "App Version":"0.3.2",
            "Test Environment": "STAGING",
            "Browser": "N/A",
            "Platform": "Linux",
            "Parallel": "Scenarios",
            "Executed": "Remote"
        }
    };

    reporter.generate(options);