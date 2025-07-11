set -euo pipefail

echo "🔧 Setting up Python virtual environment..."
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
  echo "✅ Virtualenv created at .venv/"
fi

echo "🚀 Activating virtual environment..."
# shellcheck source=/dev/null
source .venv/bin/activate

if [ -f "requirements.txt" ]; then
  echo "📦 Installing Python dependencies..."
  pip install --upgrade pip
  pip install -r requirements.txt
else
  echo "⚠️  No requirements.txt found — skipping Python deps."
fi

echo "📁 Changing to infra directory..."
cd infra

echo "🗑️  Initializing Terraform backend..."
terraform init -input=false

echo "🔥 Destroying all Terraform-managed infrastructure..."
terraform destroy -auto-approve -var-file=terraform.tfvars

echo "🚮 Teardown complete! All resources removed."

echo "🛑 Deactivating virtual environment..."
deactivate