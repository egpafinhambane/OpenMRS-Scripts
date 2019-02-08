set @ydata := '2018-12-20';
set @sismaLocationID := 200693; -- funhalouro
set @openmrsLocationID := 410 ;
	
-- update openmrs.global_property 
-- set property_value=@sismaLocationID
-- where property='esaudemetadata.hfc';
-- -- ---------------------------------------------------------
-- update openmrs.global_property 
-- set property_value=@ydata
-- where property='esaudemetadata.dateToImportTo';

-- SELECT location_id,COUNT(*) FROM openmrs.encounter GROUP BY location_id
insert into openmrs.global_property (property,property_value,description,uuid) 
values('esaudemetadata.hfc',@sismaLocationID,'health facility code',uuid());

insert into openmrs.global_property (property,property_value,description,uuid)
values('esaudemetadata.dateToImportTo',@ydata,'Date when data should be fetched to provide it',uuid());

-- source '/home/asamuel/Documents/openmrs/schema_sp_export_modified.sql';

-- step 2
UPDATE openmrs.obs en SET en.location_id = @openmrsLocationID WHERE en.location_id IS NULL OR en.location_id != @openmrsLocationID ;
UPDATE openmrs.encounter en SET en.location_id = @openmrsLocationID  WHERE en.location_id IS NULL OR en.location_id != @openmrsLocationID ;
UPDATE openmrs.visit en SET en.location_id = @openmrsLocationID  WHERE en.location_id IS NULL OR en.location_id != @openmrsLocationID ;
UPDATE openmrs.patient_program en SET en.location_id = @openmrsLocationID  WHERE en.location_id IS NULL OR en.location_id != @openmrsLocationID ;


call db_teste.proc_remove_dups_filas();
call db_teste.proc_remove_dups_buscas();
-- step 3 - Filas repetidos

-- Check if two patients are using the same NID (Problem caused by synchronization)
-- ---------------------------------------------------------------------------------
SELECT identifier,Count(*)
FROM openmrs.patient_identifier
WHERE voided=0 AND identifier_type=2
GROUP BY identifier
HAVING Count(*)>=2;


