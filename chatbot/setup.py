from setuptools import setup, find_packages

setup(
    name="kastart",
    version="2.0.0",
    description="AI-powered business assistant for SMEs",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    author="KaStart",
    author_email="your.email@example.com",
    url="https://github.com/yourusername/kastart",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: End Users/Desktop",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Office/Business",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
    ],
    python_requires=">=3.8",
    entry_points={
        "console_scripts": [
            "kastart=chatbot:main",
        ],
    },
)
