import MeridDB.*

%Clear start!
%Clear screen and delete all variables
clearvars;
clc;

%close all existing windows of matlab
close all



%Initialize database
db = MeridDB('hiwi_ro','#meridDB2019','134.130.87.47',3306);

%Request all experiments and print out
experimentOverview = db.getExperiments;
fprintf('\nFound the following experiments in database:\n')
disp(experimentOverview);

experiment_no = 0;

%Select your experiment as long as the experiment is not valid, the input
%dialog will be repeated.
while sum(ismember(experimentOverview.experiment_no,experiment_no)) < 1
    experiment_no = inputdlg('Select an experiment number: ','ExperimentNo',1);
    
    %Error if cancel
    if (isempty(experiment_no))
        error('Empty message or input dialog canceled')
    end
    experiment_no = str2num(experiment_no{1});
end

%Get metadata from database
fprintf('Get data from database \n');
db_metadata = db.getMetaData(experiment_no);

%Check if metadata was submitted
if (db_metadata == 0)
    %stop execution when no metadata was found
    return;
end

%Get specimen and rock data from database
db_specimendata = db.getSpecimenData(experiment_no, db_metadata.specimenId);

%Get experiments data
db_data = db.getExperimentData(experiment_no);

%%
permeabilityTable=db_data.getPermeability(db_specimendata.height,db_specimendata.diameter,0.5);

%%