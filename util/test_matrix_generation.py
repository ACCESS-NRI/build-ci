import pytest
import os
from unittest import mock

from matrix_generation import generate_matrix


@pytest.fixture(autouse=True)
def mock_github_output_env_var():
    with mock.patch.dict(os.environ, {"GITHUB_OUTPUT": "/dev/null"}):
        yield


class TestMatrixGeneration:
    def test_empty_args(self):
        assert generate_matrix([]) == set()

    def test_existing_package_with_no_deps(self):
        assert generate_matrix(["access-om3"]) == {"access-om3"}

    def test_existing_package_with_deps(self):
        assert generate_matrix(["libaccessom2"]) == {"libaccessom2", "cice5", "mom5"}

    def test_existing_packages_with_uncommon_deps(self):
        assert generate_matrix(["libaccessom2", "access-om3"]) == {
            "libaccessom2",
            "cice5",
            "mom5",
            "access-om3",
        }

    def test_existing_packages_with_common_deps(self):
        assert generate_matrix(["oasis3-mct", "libaccessom2"]) == {
            "oasis3-mct",
            "libaccessom2",
            "cice5",
            "mom5",
        }

    def test_unknown_package(self):
        assert generate_matrix(["foo"]) == set()

    def test_unknown_packages(self):
        assert generate_matrix(["foo", "bar"]) == set()

    def test_unknown_github_package(self):
        assert generate_matrix([".github"]) == set()

    def test_mix_of_existing_and_unknown_deps(self):
        assert generate_matrix(["datetime-fortran", "foo"]) == {
            "datetime-fortran",
            "libaccessom2",
            "cice5",
            "mom5",
        }

    def test_mix_of_unknown_and_existing_deps(self):
        assert generate_matrix(["access-om2", "cice5"]) == {"cice5"}
