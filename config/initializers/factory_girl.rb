# Add the factories from tufts_models to the load path
FactoryGirl.definition_file_paths << Pathname.new("#{TuftsModels::Engine.root.to_s}/spec/factories")