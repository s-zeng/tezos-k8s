import setuptools

with open("README.md", "r") as readme:
    long_description = readme.read()

setuptools.setup(
    name="mkchain",
    version="0.1",
    packages=["tqchain"],
    author="TQ Tezos",
    description="A utility to generate k8s configs for a Tezos blockchain",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/tqtezos/tezos-k8s",
    include_package_data=True,
    install_requires=["pyyaml", "kubernetes"],
    setup_requires=["wheel"],
    entry_points={"console_scripts": ["mkchain=tqchain.mkchain:main"]},
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.6",
)
