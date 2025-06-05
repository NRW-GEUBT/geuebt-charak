#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys


# if not calling for snakemake rule
try:
    sys.stderr = open(snakemake.log[0], "w")
except NameError:
    pass


import os
import requests
import json
from urllib.parse import urljoin


USERNAME = os.getenv("GEUEBT_API_USERNAME")
PASSWORD = os.getenv("GEUEBT_API_PASSWORD")


def login(url, username, password):
    response = requests.post(
        f"{url}/users/token",
        data={"username": username, "password": password},
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
    response.raise_for_status()
    return response.json()["access_token"]


def authenticated_request(method, endpoint, token, **kwargs):
    headers = kwargs.pop("headers", {})
    headers["Authorization"] = f"Bearer {token}"
    return requests.request(method, endpoint, headers=headers, **kwargs)


def main(settings, url, organism):
    if not USERNAME or not PASSWORD:
        raise RuntimeError("Missing API_USERNAME or API_PASSWORD env vars")
    token = login(USERNAME, PASSWORD)
    response = authenticated_request(
        "GET",
        urljoin(url, f"settings/{organism}"),
        token
    )

    if response.status_code != 200:
        raise ValueError(
            f"Failed to retrieve clusters for species {organism}"
            f"Status: {response.status_code}."
            f"Body: {response.text}"
        )


    with open(settings, "w") as fo:
        json.dump(response.json(), fo, indent = 4)


if __name__ == "__main__":
    main(
        snakemake.output['settings'],
        snakemake.params['url'],
        snakemake.params['organism'],
    )
