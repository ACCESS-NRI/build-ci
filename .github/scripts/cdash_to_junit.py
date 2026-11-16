#!/usr/bin/env python3
"""Convert spack's CDash stand-alone test reports into a single JUnit report.

`spack test run --log-format=cdash --log-file=<dir>` writes one
`<package>_<hash>_Testing.xml` per tested spec, with one `<Test>` per test part.
`spack test run --log-format=junit` instead writes one `<testcase>` per spec.
This script turns the former into JUnit so that each test part is a `<testcase>`.

Usage: cdash_to_junit.py <cdash-dir> <output-junit.xml>

The split into test parts is done by spack (`spack.reporters.extract`), and is
carried over as-is:

* Parent parts (e.g. `test_c` for `test_c_hello.c`) are their own testcases,
  without a command or output.
* The status line of a parent part ends up in the output of its last subpart,
  and parts without a status line are reported as passed. Treat the exit code
  of `spack test run` as the overall result, rather than the individual rows.
* The package-level `NO_TESTS` part is not reported.
"""

import argparse
import re
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

REPORT_SUFFIX = "_Testing.xml"

# Test output can contain characters that are not allowed in XML 1.0 (such as
# the escape character of terminal colours), which spack writes out verbatim.
INVALID_XML_CHARS = re.compile("[\x00-\x08\x0b\x0c\x0e-\x1f]")

# Values spack uses for <FullCommandLine> when a part has no command
NO_COMMAND = {"", "None", "unknown", "Not Applicable"}

SKIPPED_STATUSES = {"notrun", "skipped"}


def text(element, path):
    """Return the stripped text of the child at `path`, or an empty string."""
    return (element.findtext(path) or "").strip()


def measurement(test, name):
    """Return the value of the NamedMeasurement called `name`, or an empty string."""
    for named in test.iterfind("Results/NamedMeasurement"):
        if named.get("name") == name:
            return text(named, "Value")
    return ""


def convert_test(test, package):
    """Return the JUnit <testcase> and the status for a CDash <Test>."""
    name = text(test, "Name") or package
    status = test.get("Status", "").lower()
    try:
        time = float(measurement(test, "Execution Time"))
    except ValueError:
        time = 0.0

    command = text(test, "FullCommandLine")
    output = text(test, "Results/Measurement/Value")

    testcase = ET.Element("testcase", classname=package, name=name, time=f"{time:.6f}")

    if status == "failed":
        failure = ET.SubElement(
            testcase, "failure", message=measurement(test, "Description") or name
        )
        failure.text = output
    elif status in SKIPPED_STATUSES:
        ET.SubElement(
            testcase, "skipped", message=measurement(test, "Completion Status") or status
        )

    system_out = "\n".join(
        part for part in (f"$ {command}" if command not in NO_COMMAND else "", output) if part
    )
    if system_out:
        ET.SubElement(testcase, "system-out").text = system_out

    return testcase, status, time


def convert_report(report):
    """Return the JUnit <testsuite> for a CDash `<package>_<hash>_Testing.xml`."""
    site = ET.fromstring(INVALID_XML_CHARS.sub("", report.read_text(encoding="utf-8")))

    package = report.name[: -len(REPORT_SUFFIX)].rsplit("_", 1)[0]
    testsuite = ET.Element("testsuite", name=site.get("BuildName") or package)
    hostname = site.get("Hostname")
    if hostname is not None:
        testsuite.set("hostname", hostname)

    start = text(site, "Testing/StartTestTime")
    if start.isdigit():
        testsuite.set(
            "timestamp",
            datetime.fromtimestamp(int(start), tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%S"),
        )

    failures = skipped = 0
    total_time = 0.0
    for test in site.iterfind("Testing/Test"):
        testcase, status, time = convert_test(test, package)
        testsuite.append(testcase)
        failures += status == "failed"
        skipped += status in SKIPPED_STATUSES
        total_time += time

    testsuite.set("tests", str(len(testsuite)))
    testsuite.set("failures", str(failures))
    testsuite.set("errors", "0")
    testsuite.set("skipped", str(skipped))
    testsuite.set("time", f"{total_time:.6f}")
    return testsuite


def main():
    parser = argparse.ArgumentParser(description="Converter of Spack's CDash tests into JUnit format, one testcase per test")
    parser.add_argument("cdash_dir", type=Path, help="directory of spack's CDash reports")
    parser.add_argument("junit_file", type=Path, help="JUnit report to write")
    args = parser.parse_args()

    # Spack doesn't write a report for specs without test output, so there may be none
    testsuites = ET.Element("testsuites")
    for report in sorted(args.cdash_dir.glob(f"*{REPORT_SUFFIX}")):
        try:
            testsuites.append(convert_report(report))
        except ET.ParseError as e:
            sys.exit(f"Error: {report} is not valid XML: {e}")

    ET.indent(testsuites)
    args.junit_file.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(testsuites).write(args.junit_file, encoding="utf-8", xml_declaration=True)
    print(f"Wrote {sum(len(suite) for suite in testsuites)} testcases to {args.junit_file}")


if __name__ == "__main__":
    main()
