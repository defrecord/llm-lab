from setuptools import setup, find_packages

setup(
    name="llm_lab",
    version="0.1.0",
    packages=find_packages("src"),
    package_dir={"": "src"},
    install_requires=[
        "llm>=0.12.0",
        "ttok",
        "strip-tags",
        "files-to-prompt",
        "llm-gemini",
        "llm-bedrock",
        "llm-claude",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "black>=23.0.0",
            "ruff>=0.1.0",
            "pytest-cov>=4.1.0",
        ],
    },
    python_requires=">=3.8",
)