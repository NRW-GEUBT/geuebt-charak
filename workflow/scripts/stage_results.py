#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys


# if not calling for snakemake rule
try:
    sys.stderr = open(snakemake.log[0], "w")
except NameError:
    pass


import os
import json
import requests
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


def main(summary, sheet_out, merged, qc_out, uri, ver):
    os.makedirs(sheet_out, exist_ok=True)
    mergedlist = []
    qc = {}
    for summ in summary:
        # Get relevant fields
        with open(summ, "r") as fi:
            report = json.load(fi)
        isolate_id = report["sample"]
        charak = {}
        for k, v in report.items():
            if k in ["amr", "virulence", "plasmids", "reference_information", "Ecoli", "Salmonella", "Listeria"]:
                charak[k] = v

        # Update isolate info
        if not USERNAME or not PASSWORD:
            raise RuntimeError("Missing API_USERNAME or API_PASSWORD env vars")
        token = login(uri, USERNAME, PASSWORD)
        response = authenticated_request(
            "PUT",
            urljoin(uri, f"isolates/{isolate_id}/characterization"),
            token,
            json={
                "characterization": charak,
                "sample_info": {"geuebt_charak_ver": ver}
            }
        )   

        # Failed PUT will also be outputed to not break things in core
        dict_out = {
            "isolate_id": isolate_id,
            "characterization": charak,
            "sample_info": {"geuebt_charak_ver": ver}
        }
        mergedlist.append(dict_out)

        # Check response
        if response.status_code == 200:
            qc[isolate_id] = {"STATUS": "PASS", "MESSAGES": [response.json()["message"]]}
            
        else: # should never happen, not critical so send a warning
            qc[isolate_id] = {
                "STATUS": "WARNING",
                "MESSAGES": [
                    f"An unexpected error occured while adding characterization info."
                    f"Status: {response.status_code}."
                    f"Body: {response.text}"
                ]
            }

        with open(os.path.join(sheet_out, f"{isolate_id}.json"), "w") as fo:
            json.dump(dict_out, fo, indent=4)
    with open(merged, "w") as fo:
        json.dump(mergedlist, fo, indent=4)
    with open(qc_out, "w") as fo:
        json.dump(qc, fo, indent=4)


if __name__ == '__main__':
    main(
        snakemake.input['summary'],
        snakemake.output['sheet_out'],
        snakemake.output['merged'],
        snakemake.output['qc_out'],
        snakemake.params['API_url'],
        snakemake.params['ver'],
    )
