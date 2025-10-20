.PHONY: setup simulate features train anomaly shap eval diagnostics app local gallery thumbs features-snapshot

setup:
	Rscript -e "source('scripts/00_setup.R'); renv::snapshot(prompt=FALSE)"

simulate:
	Rscript scripts/01_simulate_data.R

features:
	Rscript scripts/02_feature_engineering.R

train:
	Rscript scripts/03_train_model.R

anomaly:
	Rscript scripts/03b_lapse_detector.R

shap:
	Rscript scripts/03c_explain_and_pd.R

eval:
	Rscript scripts/04_eval_LOSO.R

diagnostics:
	Rscript scripts/05_diagnostics_export.R

app:
	Rscript -e "shiny::runApp('shiny_app', launch.browser=TRUE)"

local:
	Rscript scripts/run_local_full.R

gallery:
	@echo "🎨 Generating deterministic gallery for case study..."
	Rscript scripts/90_make_gallery.R
	@echo "🖼️  Generating thumbnails..."
	Rscript scripts/91_thumbs.R
	@echo "✅ Gallery generation complete!"

thumbs:
	@echo "🖼️  Generating thumbnails..."
	Rscript scripts/91_thumbs.R
	@echo "✅ Thumbnail generation complete!"

features-snapshot:
	@echo "📊 Generating features snapshot with trends..."
	Rscript scripts/92_export_features_snapshot.R
	@echo "✅ Features snapshot generation complete!"
