import os
import sys
import json


def generate_matrix(
    updated_packages: list[str],
) -> set[str]:
    # set of all the dependant packages to build an image for
    packages: set[str] = set()
    # list of all the compilers
    compilers: list[dict[str, str]] = [
        {"name": "intel", "package": "intel-oneapi-compilers", "version": "2021.1.2"}
    ]

    # using the dependant mappings in the file
    with open("./util/supported-dependency-mapping.txt", "r") as file:
        print(f"Args are: {updated_packages}")

        # for each of the main packages that were updated in spack_packages
        for updated_package in updated_packages:
            print(f"Looking for {updated_package}")

            # find the line that corresponds to the main package we're looking for
            for line in file:
                package_mapping: list[str] = line.split()
                print(
                    f"Package: {package_mapping[0]}, Dependents: {package_mapping[1:] if len(package_mapping) > 1 else 'None'}"
                )

                if package_mapping[0] == updated_package:
                    print(f"adding {package_mapping}")
                    # if we've found it, add it to the set of packages that we will need to generate an image for
                    packages.update(package_mapping)
                    print(f"packages is now {packages}\n")
                    break
            # reset the file pointer to the beginning of the file
            file.seek(0)

    # send this to the special env var that handles output in github actions
    # turning the set of packages into a list and then into a json object
    with open(os.environ["GITHUB_OUTPUT"], "a") as out:
        print(f"packages={json.dumps(list(packages))}", file=out)
        print(f"compilers={json.dumps(compilers)}", file=out)

    print(json.dumps(list(packages)))

    return packages


if __name__ == "__main__":
    generate_matrix(sys.argv[1:])
