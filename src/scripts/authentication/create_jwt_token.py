from datetime import timedelta
import json
import argparse
import jwcrypto.jwk as jwk
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning) 
import python_jwt

def generate_other_headers(jwks_file_path: str) -> dict:
    try:
        with open(jwks_file_path, 'rb') as fh:
            return {"kid": json.loads(fh.read())['keys'][0]['kid']}
    except Exception as e:
        raise ValueError(e)


def retrieve_jwks_key(pem_file_path: str):
    try:
        # Load the PEM file containing JSON Web Key (JWK)
        with open(pem_file_path, 'rb') as fh:
            slurm_jwks_pem = fh.read()

        # Load JWK from private.pem file
        return jwk.JWK.from_pem(slurm_jwks_pem)
    except Exception as e:
        raise ValueError(e)


def main():
    parser = argparse.ArgumentParser(description='jwt token generator')
    parser.add_argument("--pem_file_path", 
                        required=True, 
                        type=str, 
                        help="path to pem file used to generate jwt token")
    parser.add_argument("--jwks_json_file_path", 
                        required=True, 
                        type=str, 
                        help="path to jwks.json file used to generate jwt token")
    args = parser.parse_args()

    jwks_key = retrieve_jwks_key(args.pem_file_path)

    print(python_jwt.generate_jwt(claims={'sun': 'slurm','algorithm':'RS256'},
                                  priv_key=jwks_key, 
                                  algorithm='RS256',
                                  lifetime=timedelta(minutes=60),
                                  other_headers=generate_other_headers(args.jwks_json_file_path)))


if __name__ == "__main__":
    main()

