import os
import sys
import json

packages = set()
compilers = [
    {
        "name": "intel",
        "package": "intel-oneapi-compilers",
        "version": "2021.1.2"
    }
]

with open("./util/supported-dependency-mapping.txt", "r") as file:
    for updated_package in sys.argv[1:]:
        for line in file:
            package_mapping = line.split()
            
            if package_mapping[0] == updated_package:
                packages.update(package_mapping)

with open(os.environ['GITHUB_OUTPUT'], "a") as out:
    print(f"packages={json.dumps(list(packages))}", file=out)
    print(f"compilers={json.dumps(compilers)}", file=out)
