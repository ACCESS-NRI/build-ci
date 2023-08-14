# Convenience script for generating new Spack buildcache keypair

# Create and export new keypair
spack gpg create ACCESS-NRI access.nri@anu.edu.au \
--export ./access-nri.pub \
--export-secret ./access-nri.priv

# Publish public key to buildcache
spack publish -m s3_buildcache
