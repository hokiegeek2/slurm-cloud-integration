import jwcrypto.jwk as jwk
 
# Generate JSON Web Key (JWK)
key = jwk.JWK.generate(kty='RSA', size=2048)
 
# Export JWK to private PEM bytes object
slurm_jwks_pem = key.export_to_pem(private_key=True, password=None)
 
# Save Private PEM bytes object to file
with open('./slurm-jwks.pem', 'wb') as f:
         f.write(slurm_jwks_pem)
