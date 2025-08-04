# SCRIPT TAKES NO ARGUMENTS
# ./govulncheck-modules.sh

# Files to exclude from govulncheck
excludeDirs=(
  "./internal/e2e"
  "./submodules/solarwinds-otel-collector-core/internal/tools"
)

pruneExpr=""
for dir in "${excludeDirs[@]}"; do
  pruneExpr="$pruneExpr -path \"$dir\" -prune -o"
done

# Find all go.mod files and run govulncheck in their directories
echo "CHECKING ALL MODULES EXCEPT EXCLUDED DIRECTORIES: ${excludeDirs[*]}"
eval find . $pruneExpr -name "go.mod" -print0 | while IFS= read -r -d '' modfile; do
    dir=$(dirname "$modfile")
    printf "\n%s\n" "$dir"
    # Run govulncheck in the module directory
    govulncheck -C ${dir} -mode=source -scan=module || true
done