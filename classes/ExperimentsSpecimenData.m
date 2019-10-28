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
% Biebricher 2019-10-25
%   * Properties as struct containing of value/unit pair
    
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
        rockDensitySaturated; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
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
            obj.dataTable.Properties.VariableUnits{'massSat'} = 'g';
            obj.dataTable.Properties.VariableUnits{'massWet'} = 'g';
            obj.dataTable.Properties.VariableUnits{'massDry'} = 'g';
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
            experimentNo = single(obj.experimentNo);
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
            height.value = single(obj.dataTable.height);
            height.unit = obj.dataTable.Properties.VariableUnits{'height'};
        end
        
        function diameter = get.diameter(obj) 
            diameter.value = single(obj.dataTable.diameter);
            diameter.unit = obj.dataTable.Properties.VariableUnits{'diameter'};
        end
        
        function massSaturated = get.massSaturated(obj) 
            massSaturated.value = single(obj.dataTable.massSat);
            massSaturated.unit = obj.dataTable.Properties.VariableUnits{'massSat'};
        end
        
        function massDry = get.massDry(obj) 
            massDry.value = single(obj.dataTable.massDry);
            massDry.unit = obj.dataTable.Properties.VariableUnits{'massDry'};
        end
        
        function massWet = get.massWet(obj) 
            massWet.value = single(obj.dataTable.massWet);
            massWet.unit = obj.dataTable.Properties.VariableUnits{'massWet'};
        end
        
        function densityWet = get.rockDensityWet(obj) 
            densityWet.value = single(obj.dataTable.densityWet);
            densityWet.unit = obj.dataTable.Properties.VariableUnits{'densityWet'};
        end
        
        function density = get.rockDensitySaturated(obj) 
            density.value = single(obj.dataTable.densitySat);
            density.unit = obj.dataTable.Properties.VariableUnits{'densitySat'};
        end
        
        function density = get.rockDensityDry(obj) 
            density.value = single(obj.dataTable.densityDry);
            density.unit = obj.dataTable.Properties.VariableUnits{'densityDry'};
        end
        
        function density = get.rockDensityGrain(obj) 
            density.value = single(obj.dataTable.densityGrain);
            density.unit = obj.dataTable.Properties.VariableUnits{'densityGrain'};
        end
        
        function densityDry = get.densityDry(obj) 
            densityDry.value = single(obj.dataTable.massWet/(obj.dataTable.height*pi*(obj.dataTable.diameter/2)^2));
            densityDry.unit = obj.dataTable.Properties.VariableUnits{'densitySat'};
        end
        
        function densitySaturated = get.densitySaturated(obj) 
            densitySaturated.value = single(obj.dataTable.massSat/(obj.dataTable.height*pi*(obj.dataTable.diameter/2)^2));
            densitySaturated.unit = obj.dataTable.Properties.VariableUnits{'densitySat'};
        end
        
        function permeabilityCoefficient = get.permeabilityCoefficient(obj) 
            permeabilityCoefficient.value = single(obj.dataTable.permCoeff);
            permeabilityCoefficient.unit = obj.dataTable.Properties.VariableUnits{'permCoeff'};
        end
        
        function porosity = get.porosity(obj) 
            porosity.value = single(obj.dataTable.porosity);
            porosity.unit = obj.dataTable.Properties.VariableUnits{'porosity'};
        end
        
        function voidRatio = get.voidRatio(obj) 
            voidRatio.value = single(obj.dataTable.voidRatio);
            voidRatio.unit = obj.dataTable.Properties.VariableUnits{'voidRatio'};
        end
        
        function uniAxialCompressiveStrength = get.uniAxialCompressiveStrength(obj) 
            uniAxialCompressiveStrength.value = single(obj.dataTable.uniAxCompStrength);
            uniAxialCompressiveStrength.unit = obj.dataTable.Properties.VariableUnits{'uniAxCompStrength'};
        end
        
        function uniAxialEModulus = get.uniAxialEModulus(obj) 
            uniAxialEModulus.value = single(obj.dataTable.uniAxEModulus);
            uniAxialEModulus.unit = obj.dataTable.Properties.VariableUnits{'uniAxEModulus'};
        end
        
        
    end
end