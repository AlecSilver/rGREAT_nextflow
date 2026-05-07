#!/usr/bin/env bash
# generate_random_beds.sh
# Generates 3 randomized BED files with 100 regions each using bedtools random

set -euo pipefail

# --- Configuration ---
NUM_FILES=3
NUM_REGIONS=100
REGION_LEN=1000          # fixed region length (bedtools random uses -l)
GENOME="assets/mm9.chom.sizes"     # genome chrom.sizes file

# --- Create a genome chrom.sizes file if one doesn't exist ---
if [[ ! -f "$GENOME" ]]; then
    echo "Creating hg38 chrom.sizes file: $GENOME"
    cat > "$GENOME" <<'EOF'
chr1	248956422
chr2	242193529
chr3	198295559
chr4	190214555
chr5	181538259
chr6	170805979
chr7	159345973
chr8	145138636
chr9	138394717
chr10	133797422
chr11	135086622
chr12	133275309
chr13	114364328
chr14	107043718
chr15	101991189
chr16	90338345
chr17	83257441
chr18	80373285
chr19	58617616
chr20	64444167
chr21	46709983
chr22	50818468
chrX	156040895
chrY	57227415
EOF
fi

# --- Generate BED files ---
for i in $(seq 1 "$NUM_FILES"); do
    OUTFILE="random_regions_${i}.bed"
    echo "Generating $OUTFILE ..."

    bedtools random \
        -n "$NUM_REGIONS" \
        -l "$REGION_LEN" \
        -g "$GENOME" \
        -seed "$RANDOM" \
    | sort -k1,1 -k2,2n \
    > "$OUTFILE"

    echo "  -> $OUTFILE written ($(wc -l < "$OUTFILE") regions)"
done

echo ""
echo "Done! Files generated:"
ls -lh random_regions_*.bed