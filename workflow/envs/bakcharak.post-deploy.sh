#!/usr/bin/env bash
# set -Eeu

# Repo URL
bakcharak_repo="https://gitlab.com/bfr_bioinformatics/bakcharak.git"

# Commit hash to use
commit="48ed26054bde528ea4f2f8a104c3dfb95154fa1e"

# Local directory to save the Repo
local_dir="${CONDA_PREFIX}/bakCharak/"

# if already exists, wipe it clean and redo clone
[ -d "$local_dir" ] && rm -rf "$local_dir"

# clone and checkout repo
echo "Cloning BakCharak and checking out stable commit" &>> "$local_dir/deploy_log.txt"
git clone -q "$bakcharak_repo" "$local_dir"
cd "$local_dir"
git checkout "$commit"

# Patch
echo "Applying patches" &>> "$local_dir/deploy_log.txt"
patch -s --directory="$local_dir" --strip=1 &>> "$local_dir/deploy_log.txt" << 'END' 
diff --unified --recursive --no-dereference bakcharak-orig/envs/bakcharak_extra.yaml bakcharak/envs/bakcharak_extra.yaml
--- bakcharak-orig/envs/bakcharak_extra.yaml    2024-12-23 10:43:51.828346873 +0100
+++ bakcharak/envs/bakcharak_extra.yaml 2024-12-23 10:40:40.000000000 +0100
@@ -17,7 +17,7 @@
   - fastani[version='>=1.31']
   - mash[version='>=2.2.2']
   - mlst[version='>=2.19.0']
-  - ncbi-amrfinderplus #[version='>=3.12.8']
+  - ncbi-amrfinderplus=3.12.8
   - platon[version='>=1.6.0']
   - prodigal[version='>=2.6.3']
   #- prokka[version='>=1.14.6']

END

# Update nev with bakcharak yaml
if [[ $(which mamba) == "" ]]; then
  echo $(which conda) &>> "$local_dir/deploy_log.txt"
  echo $(conda -v) &>> "$local_dir/deploy_log.txt" 
  conda env update --file "$local_dir/envs/bakcharak_extra.yaml" -p $CONDA_PREFIX &>> "$local_dir/deploy_log.txt"
  amrfinder -u &>> "$local_dir/deploy_log.txt"
else
  echo $(which mamba) &>> "$local_dir/deploy_log.txt"
  echo $(mamba -V) &>> "$local_dir/deploy_log.txt" 
  mamba env update --file "$local_dir/envs/bakcharak_extra.yaml" -p $CONDA_PREFIX &>> "$local_dir/deploy_log.txt"
  amrfinder -u &>> "$local_dir/deploy_log.txt"
fi

# Install databases
echo "Installing databases"
bash "$local_dir/scripts/bakcharak_setup.sh" --amrfinder_update --databases --status --auto &>> "$local_dir/deploy_log.txt" 
