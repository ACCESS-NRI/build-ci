import os
import sys
import json

# set of all the dependant packages to build an image for
packages = set()
# list of all the compilers
compilers = [
    {
        "name": "intel",
        "package": "intel-oneapi-compilers",
        "version": "2021.1.2"
    }
]

# using the dependant mappings in the file
with open("./util/supported-dependency-mapping.txt", "r") as file:
    print(f"Args are: {sys.argv}")

    # for each of the main packages that were updated in spack_packages
    for updated_package in sys.argv[1:]:
        print(f'Looking for {updated_package}')

        # find the line that corresponds to the main package we're looking for
        for line in file:
            package_mapping = line.split()
            print(f"Package: {package_mapping[0]}, Dependents: {package_mapping[1:] if len(package_mapping) > 1 else 'None'}")
            
            if package_mapping[0] == updated_package:
                print(f'adding {package_mapping}')
                # if we've found it, add it to the set of packages that we will need to generate an image for
                packages.update(package_mapping)
                print(f'packages is now {packages}\n')
                break

# send this to the special env var that handles output in github actions
# turning the set of packages into a list and then into a json object
with open(os.environ["GITHUB_OUTPUT"], "a") as out:
    print(f"packages={json.dumps(list(packages))}", file=out)
    print(f"compilers={json.dumps(compilers)}", file=out)
