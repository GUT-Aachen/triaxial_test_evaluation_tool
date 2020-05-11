import MeridDB.*

%Clear start!
%Clear screen and delete all variables
%clearvars;
%clc;

%close all existing windows of matlab
close all
 


%Initialize database
dbConnection = MeridDB('MySQL-User','MySQL-Password','MySQL-IP',MySQL-Port);

%Request all experiments and print out
experimentOverview = dbConnection.getExperiments;
fprintf('\nFound the following experiments in database:\n')
disp(experimentOverview);

experimentNo = 0;

%Select your experiment as long as the experiment is not valid, the input
%dialog will be repeated.
while sum(ismember(experimentOverview.experimentNo,experimentNo)) < 1
    experimentNo = inputdlg('Select an experiment number: ','ExperimentNo',1);
    
    %Error if cancel
    if (isempty(experimentNo))
        error('Empty message or input dialog canceled')
    end
    experimentNo = str2num(experimentNo{1});
end

%Get metadata from database
fprintf('Get data from database \n');
dbMetaData = dbConnection.getMetaData(experimentNo);

%Check if metadata was submitted
if (dbMetaData == 0)
    %stop execution when no metadata was found
    return;
end

%Get specimen and rock data from database
dbSpecimenData = dbConnection.getSpecimenData(experimentNo, dbMetaData.specimenId);

%Get experiments data
dbData = dbConnection.getExperimentData(experimentNo);

%%
permeabilityTable=dbData.getPermeability(dbSpecimenData.height.value, dbSpecimenData.diameter.value ,0.5);

%%