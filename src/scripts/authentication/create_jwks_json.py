import argparse
import json
import jwcrypto.jwk as jwk

def create_jwks_json(pem_file_path: str):
    # Load the PEM file containing JSON Web Key (JWK)
    with open(pem_file_path, 'rb') as fh:
         slurm_jwks_pem = fh.read()

    # Load JWK from private.pem file
    jwks_key = jwk.JWK.from_pem(slurm_jwks_pem)

    # Export JWK as JSON string
    return jwk.JWK.export_private(jwks_key)

def create_jwks_json_file(pem_file_path: str, jwks_json_file_path) -> None:
    jwks_json_string = create_jwks_json(pem_file_path)
    jwks_dict = {"keys": [jwks_json_string]}
    with open(jwks_json_file_path, 'w') as fh:
        fh.write(json.dumps(jwks_dict))

def main():
    parser = argparse.ArgumentParser(description='jwks.json generator')
    parser.add_argument("--pem_file_path", required=True, type=str, help="path to pem file used to generate jwks.json")
    parser.add_argument("--jwks_json_file_path", required=False, type=str, help="path to write jwks.json to")
    args = parser.parse_args()

    pem_file_path = args.pem_file_path
    if args.jwks_json_file_path:
       create_jwks_json_file(args.pem_file_path,args.jwks_json_file_path)
    else:
       print(create_jwks_json_file(pem_file_path,))


if __name__ == "__main__":
    main()
