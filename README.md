# Triaxial Test Evaluation Tool

> With this evaluation tool you can check and interpret the results of a modified <a href="https://en.wikipedia.org/wiki/Triaxial_shear_test" target="_blank">`geotechnical triaxial test`</a>. With this aperature it is possible to confine a probe, rise the axial stress and measure the permeability of the probe at all stages. The tool was developed as part of a joint project called MERID (Microstructural Influence on Reservoir Integrity at Variable Hydromechanical Conditions) funded by the German Federal Ministry of Education and Research as part of GEO:N Project ([Geoforschung für Nachhaltigkeit](https://www.bmbf.de/de/geoforschung-2398.html)) to evaluate the results of a special assembled large triaxial cell. This tool consists of a backend and a frontend both assembled in MathWorks Matlab. The backend creates a connection to a MySQL-Database where all experiments results are stored.

![License: GNU](https://img.shields.io/github/license/froido/merid_triaxial_data_analysis?style=flat-square)
![License: GNU](https://img.shields.io/github/release-date/froido/merid_triaxial_data_analysis?style=flat-square)
![License: GNU](https://img.shields.io/github/v/release/froido/merid_triaxial_data_analysis?style=flat-square)

---

## Features

### Frontend (GUI)

 - List and overview all experiments in database
 - Keep rock/soil parameters always in view
 - Check experiment description and additional comments
 - Get an overview of important parameters and their connection
 - Show experiments timelog related to experiments data
 - Change integration timestep for permeability calculation
 - Plot graphs with variable x-axis and two possible y-axis
 - Compare to different/independent experiments
 - Export graphs easiely as raster graphics (1200 DPI) or vector graphics

<p align="center">
  <img src = "https://github.com/froido/merid_triaxial_data_analysis/blob/master/sample/experiments_list.png" width=300> <img src = "https://github.com/froido/merid_triaxial_data_analysis/blob/master/sample/data_overview.png" width=300>
</p><p align="center">
  <img src = "https://github.com/froido/merid_triaxial_data_analysis/blob/master/sample/data_vs_timelog.png" width=300> <img src = "https://github.com/froido/merid_triaxial_data_analysis/blob/master/sample/comparison.png" width=300>
</p>
 

### Backend

 - Class oriented programming in matlab
 - Connection to MySQL database
 - Interface between frontend (GUI) and MySQL database
 - Seperated classes for handling experiments meta data `ExperimentsMetaData`, meassured values `ExperimentsData`, rock/soil related data `ExperimentsSpecimenData`, MySQL database connection `MeridDB`, interface to frontend (GUI) `TriaxTestHandler`
 - Measured data cleansing like filtering NaN values
 - Calculating permeability and permeability coefficient according to fluid (water) properties with help of <a href="https://github.com/isantosruiz" target="_blank">isantosruiz</a> <a href="https://github.com/isantosruiz/water-properties" target="_blank">`water-properties`</a> repository.


---

## Requirements

 - Matlab Version 2019b or newer
 - [Matlab Curve Fitting Toolbox](https://de.mathworks.com/products/curvefitting.html) for permeability calculation
 - [JDBC MySQL Connector](https://dev.mysql.com/doc/connector-j/8.0/en/) included in Matlab `javaclasspath` (dynamic or static)
 - Configured MySQL database engine (a skript creating the skeleton für the database is comming soon) which includes all triaxial test datasets
 
 ---
 
## Setup

 - Have a running MathWorks Matlab 2019b or higher engine with installed curve fitting toolbox.
 - Have a running MySQL engine with a database according to the needs of this tool. To create a valid database you can use the (upcomming) batch file in this repo.
 - Download [JDBC MySQL Connector](https://dev.mysql.com/doc/connector-j/8.0/en/) to your local machine.
 - Add JDBC MySQL Connector to `javaclasspath` dynamic part
  ```matlab
  >> javaaddpath('/your_folder/mysql-connector-java-8.0.20.jar')
  ```
 - Check if adding was sucessfull
  ```matlab
  >> javaclasspath
    
    /some_other_folder/some_file.jar
    
        DYNAMIC JAVA PATH

    /your_folder/mysql-connector-java-8.0.20.jar
  ```
 - Clone this repo to your local machine
 - Run `GUI.mlapp`
 

---

## Usage

1. Adding triaxial test datasets to the database
2. Start the `Triaxial Test Evaluation Tool` via `GUI.mlapp`.
3. Select a main experiment from the shown list.
4. Evaluate your test results and enjoy.

---

## Additional Hints

 - Matlab has often problems with the timezone set in Oracle MySQL database under windows systems. CET (german: MET) is unknown for matlab, which leets to an error. Set the timezone manualy to e.g. `+02:00` manualy.
 ```mysql
 SET GLOBAL time_zone = '+02:00';
 ```
 - Due to very big datasets the global buffer size shall be extended in MySQL database e.g. 4 gigabyte
 ```mysql
 SET GLOBAL innodb_buffer_pool_size=4294967296;
 ```
 - For unknown reasons the GUI of matlab lags sometimes after a couple of changes done in the graphs. You have two options: kill or wait.

---

## Support

Reach out to me at one of the following places!

- Website at <a href="http://www.geotechnik.rwth-aachen.de/index.php?section=Biebricher_en" target="_blank">`www.geotechnik.rwth-aachen.de`</a>

---

## License

![License: GNU](https://img.shields.io/github/license/froido/merid_triaxial_data_analysis?style=flat-square)

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details

---

## Thanks
to *isantosruiz* for *water-properties* ![isantosruiz/water-properties](https://img.shields.io/github/license/isantosruiz/water-properties?style=flat-square)


