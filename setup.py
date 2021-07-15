from setuptools import setup, find_packages

setup(
    name="bakerydemo",
    version="0.1.0",
    description="Bakerydemo modified app",
    packages=find_packages(),
    include_package_data=True,
    scripts=["manage.py"],

    install_requires=["Django>=3.1",
                      #was "django-dotenv==1.4.1python",
                      "django-dotenv==1.4.2",
                      "wagtail>=2.9",
                      "Pillow>=8.1.0",
                      "wagtailfontawesome>=1.1.3"],
    extras_require={
        "production": [
            "elasticsearch==5.5.3",
            # Additional dependencies for Heroku, AWS, and Google Cloud deployment
            "dj-database-url==0.4.1",
            "uwsgi>=2.0.17,<2.1",
            "psycopg2>=2.7,<3.0",
            "whitenoise>=5.0,<5.1",
            "boto3==1.9.189",
            "google-cloud-storage==1.20.0",
            "django-storages>=1.8,<1.9",
            # For retrieving credentials and signing requests to Elasticsearch
            "botocore>=1.12.33,<1.13",
            "aws-requests-auth==0.4.0",
            "django-redis==4.11.0",
            "django_cache_url==2.0.0"
        ],
        "test": [
            "colorama>=0.3.3",
            "coverage>=4.0.3",
            "django-nose>=1.4.2",
            "nose>=1.3.7",
            "pinocchio>=0.4.2"
        ]
    }
)
