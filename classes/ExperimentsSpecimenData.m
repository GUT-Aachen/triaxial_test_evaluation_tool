classdef ExperimentsSpecimenData < handle
%Class to handle the rock data of MERID triaxial experiments. The
%experiment number has to be given while creating the class object.
%All metadata information like start and end time, comments or a
%description can be read directly from the class.
%Within the class the data will be saved in a table (metaDataTable). All
%depending variables like (description, short, etc.) are empty. They are some kind of
%proxy values to be able to work with the values as if they where saved in
%the variables.
%
% Biebricher 2019-05-13
%   * Added variable massWet incl. getter
% Biebricher 2019-10-22
%   * Match camelCase
    
    properties (SetAccess = immutable)
        experimentNo; %Number of the experiment the data in this object contains to.
    end
    
    properties (SetAccess = private)
        specimen; %Proxyvariable for name of specimen in rockdata. Data is only saved in rockDataTable.
        rockType; %Proxyvariable for name of rock in rockdata. Data is only saved in rockDataTable.
        rockDescription; %Proxyvariable for rock description in rockdata. Data is only saved in rockDataTable.
        height; %Proxyvariable for height of specimen in rockdata. Data is only saved in rockDataTable.
        diameter; %Proxyvariable for diameter of specimen in rockdata. Data is only saved in rockDataTable.
        massSaturated; %Proxyvariable for mass of saturated specimen in rockdata. Data is only saved in rockDataTable.
        massWet; %Proxyvariable for mass of wet specimen in rockdata. Data is only saved in rockDataTable.
        massDry; %Proxyvariable for mass of dry specimen in rockdata. Data is only saved in rockDataTable.
        rockDensityWet; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        rockDensitySatturated; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        rockDensityDry; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        rockDensityGrain; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        densityDry;
        densitySaturated;
        permeabilityCoefficient; %Proxyvariable for permeability coefficient of rock in rockdata. Data is only saved in rockDataTable.
        porosity; %Proxyvariable for porosity of rock in rockdata. Data is only saved in rockDataTable.
        voidRatio; %Proxyvariable for void ratio of rock in rockdata. Data is only saved in rockDataTable.
        uniAxialCompressiveStrength; %Proxyvariable for uni axial compressive strength of rock in rockdata. Data is only saved in rockDataTable.
        uniAxialEModulus; %Proxyvariable for e module of uni axial compressive strength test of rock in rockdata. Data is only saved in rockDataTable.
        dataTable; %Table containing all rockdata from database
        dataTable_comparison
    end
    
    methods
        function obj = ExperimentsSpecimenData(experimentNo)
        %The experiment number (immutable) has to be set int the constructor and can
        %not be changed later.
            obj.experimentNo = experimentNo;
        end
        
        %SETTER
        function obj = setDataAsTable(obj, dataTable)
        %Set all metadata for the experiment into the object.
        %Input parameter: table with rockData
            obj.dataTable = dataTable;
            
            obj.dataTable.Properties.VariableUnits{'height'} = 'cm';
            obj.dataTable.Properties.VariableUnits{'diameter'} = 'cm';
            obj.dataTable.Properties.VariableUnits{'massSat'} = 'kg';
            obj.dataTable.Properties.VariableUnits{'massWet'} = 'kg';
            obj.dataTable.Properties.VariableUnits{'massDry'} = 'kg';
            obj.dataTable.Properties.VariableUnits{'densityWet'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'densitySat'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'densityDry'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'densityGrain'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'permCoeff'} = 'm/s';
            obj.dataTable.Properties.VariableUnits{'porosity'} = '-';
            obj.dataTable.Properties.VariableUnits{'voidRatio'} = '-';
            obj.dataTable.Properties.VariableUnits{'uniAxCompStrength'} = 'kN/m²';
            obj.dataTable.Properties.VariableUnits{'uniAxEModulus'} = 'kN/m²';
            
            
            disp([class(obj), ': ', 'Data set sucessfully']);
        end
        
        %GETTER
        function experimentNo = get.experimentNo(obj) 
            experimentNo = obj.experimentNo;
        end
        
        function specimen = get.specimen(obj) 
            specimen = obj.dataTable.specimenName{1};
        end
        
        function rockType = get.rockType(obj) 
            rockType = obj.dataTable.rockName{1};
        end
        
        function rockDescription = get.rockDescription(obj) 
            rockDescription = obj.dataTable.description{1};
        end
        
        function height = get.height(obj) 
            height = obj.dataTable.height;
        end
        
        function diameter = get.diameter(obj) 
            diameter = obj.dataTable.diameter;
        end
        
        function massSaturated = get.massSaturated(obj) 
            massSaturated = obj.dataTable.massSat;
        end
        
        function massDry = get.massDry(obj) 
            massDry = obj.dataTable.massDry;
        end
        
        function massWet = get.massWet(obj) 
            massWet = obj.dataTable.massWet;
        end
        
        function densityWet = get.rockDensityWet(obj) 
            densityWet = obj.dataTable.densityWet;
        end
        
        function density = get.rockDensitySatturated(obj) 
            density = obj.dataTable.densitySat;
        end
        
        function density = get.rockDensityDry(obj) 
            density = obj.dataTable.densityDry;
        end
        
        function density = get.rockDensityGrain(obj) 
            density = obj.dataTable.densityGrain;
        end
        
        function densityDry = get.densityDry(obj) 
            densityDry = obj.dataTable.massWet/(obj.dataTable.height*pi*(obj.dataTable.diameter/2)^2);
        end
        
        function densitySaturated = get.densitySaturated(obj) 
            densitySaturated = obj.dataTable.massSat/(obj.dataTable.height*pi*(obj.dataTable.diameter/2)^2);
        end
        
        function permeabilityCoefficient = get.permeabilityCoefficient(obj) 
            permeabilityCoefficient = obj.dataTable.permCoeff;
        end
        
        function porosity = get.porosity(obj) 
            porosity = obj.dataTable.porosity;
        end
        
        function voidRatio = get.voidRatio(obj) 
            voidRatio = obj.dataTable.voidRatio;
        end
        
        function uniAxialCompressiveStrength = get.uniAxialCompressiveStrength(obj) 
            uniAxialCompressiveStrength = obj.dataTable.uniAxCompStrength;
        end
        
        function uniAxialEModulus = get.uniAxialEModulus(obj) 
            uniAxialEModulus = obj.dataTable.uniAxEModulus;
        end
        
        
    end
end