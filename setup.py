# MIT License
#
# Copyright (c) 2021 Keisuke Sehara
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from setuptools import setup, find_packages, Extension

if False:
    try:
        import gwappa_import_module_test
    except ImportError:
        import warnings
        warnings.warn("Test warning",
                      RuntimeWarning,
                      stacklevel=2)

try:
    from Cython.Build import cythonize
except ImportError:
    import warnings
    warnings.warn("Cython installation not found",
                  RuntimeWarning,
                  stacklevel=2)
    def cythonize(*args, **kwargs):
        return None

try:
    import numpy
except ImportError:
    import warnings
    warnings.warn("NumPy installation not found",
                  RuntimeWarning,
                  stacklevel=2)
    class numpy:
        @staticmethod
        def get_include():
            return "."

extensions = [
    Extension(
        "labcamera_tis", ["labcamera_tis/*.pyx",
                          "labcamera_tis/property_utils.cpp",
                          "labcamera_tis/sink_utils.cpp"],
        language="c++",
        include_dirs=["lib/include", "labcamera_tis", numpy.get_include()], # to be filled the user
        library_dirs=["lib/link",], # to be filled by the user
        libraries=["tis_udshl12_x64",],
        define_macros=[("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION")]
    )
]

setup(
    name='ks-labcamera-tis',
    version="0.1.0",
    description='a Cython wrapper library for the ImagingSource camera control.',
    url='https://github.com/gwappa/python-labcamera-tis',
    author='Keisuke Sehara',
    author_email='keisuke.sehara@gmail.com',
    license='MIT',
    python_requires=">=3.7",
    install_requires=[
        'numpy',
        'Cython',
    ],
    classifiers=[
        'Development Status :: 3 - Alpha',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        ],
    ext_modules=cythonize(
                    extensions,
                    compiler_directives={
                        "language_level": 3,
                    }
                ),
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
)
