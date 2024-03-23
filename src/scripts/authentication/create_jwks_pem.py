import argparse
import jwcrypto.jwk as jwk


def generate_jwks_pem(pem_file_path: str) ->  None:
    # Generate JSON Web Key (JWK)
    key = jwk.JWK.generate(kty='RSA', size=2048)
 
    # Export JWK to private PEM bytes object
    slurm_jwks_pem = key.export_to_pem(private_key=True, password=None)
 
    # Save private PEM bytes object to file
    with open(pem_file_path, 'wb') as f:
         f.write(slurm_jwks_pem)


def main():
    parser = argparse.ArgumentParser(description='jwks pem generator')
    parser.add_argument("--pem_file_path",
                        required=True,
                        type=str,
                        help="path to pem file used to generate jwt token")
    args = parser.parse_args()

    generate_jwks_pem(args.pem_file_path)

if __name__ == "__main__":
    main()
