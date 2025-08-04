# SCRIPT TAKES 1 ARGUMENT, PATH TO BINARIES TO CHECK
# ./govulncheck-binaries.sh "/Users/glutius.maximus/go/bin"

if [ "$#" -ne 1 ]; then
  echo "Error: Missing BINARY PATH parameter. Please provide a value."
  exit 2
fi

# Finds all binaries in the provided directory and runs govulncheck on them
echo "CHECKING ALL BINARIES IN DIRECTORY: $1"
for binary in ${1}/*; do
  if [ -f "$binary" ]; then
    printf "\n%s\n" "$binary"
    # Run govulncheck on the binary
    govulncheck -mode=binary "$binary" || true
  fi
done
