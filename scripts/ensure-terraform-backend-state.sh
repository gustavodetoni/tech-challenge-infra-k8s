#!/usr/bin/env bash
set -euo pipefail

bucket="${1:?bucket is required}"
key="${2:?state key is required}"
region="${3:?region is required}"

if aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
  echo "Terraform state bucket exists: $bucket"
else
  echo "Terraform state bucket is not accessible. Attempting to create: $bucket"
  if [ "$region" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$bucket" --region "$region"
  else
    aws s3api create-bucket \
      --bucket "$bucket" \
      --region "$region" \
      --create-bucket-configuration LocationConstraint="$region"
  fi
fi

aws s3api put-bucket-versioning \
  --bucket "$bucket" \
  --versioning-configuration Status=Enabled >/dev/null 2>&1 || true

if aws s3api head-object --bucket "$bucket" --key "$key" >/dev/null 2>&1; then
  echo "Terraform state object exists: s3://$bucket/$key"
  exit 0
fi

tmp_state="$(mktemp)"
trap 'rm -f "$tmp_state"' EXIT
lineage="$(uuidgen 2>/dev/null || date +%s)"
cat > "$tmp_state" <<EOF
{
  "version": 4,
  "terraform_version": "1.6.0",
  "serial": 1,
  "lineage": "$lineage",
  "outputs": {},
  "resources": [],
  "check_results": null
}
EOF

echo "Terraform state object is not readable. Creating bootstrap state: s3://$bucket/$key"
aws s3api put-object \
  --bucket "$bucket" \
  --key "$key" \
  --body "$tmp_state" \
  --content-type "application/json" \
  --if-none-match "*" >/dev/null
