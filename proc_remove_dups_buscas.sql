DELIMITER $$
CREATE DEFINER=`esaude`@`%` PROCEDURE `proc_remove_dups_buscas`()
BEGIN
  DECLARE dup int;
  
  SELECT count(*) INTO dup 
        from (SELECT patient_id, encounter_datetime, COUNT(*)
			   FROM   openmrs.encounter
			   WHERE  voided = 0 AND encounter_type = 21
			   GROUP BY 1 , 2
			   HAVING COUNT(*) >= 2) duplicados;
 
 
   WHILE dup > 0 DO
    
 		DELETE FROM export_db.t_void_duplo;
 		SELECT Min(encounter_id)
			FROM openmrs.encounter,(
				SELECT patient_id,encounter_datetime
				FROM openmrs.encounter
				WHERE voided=0 AND encounter_type=21 GROUP BY 1,2 
				HAVING Count(*)>=2 )duplo_tarv
		WHERE encounter.patient_id=duplo_tarv.patient_id
		AND encounter.encounter_datetime=duplo_tarv.encounter_datetime AND encounter_type=21 
		AND encounter.voided=0 
		GROUP BY duplo_tarv.patient_id;

	 	UPDATE openmrs.encounter SET voided=1	WHERE encounter_id IN(SELECT encounter_id 
 					  FROM export_db.t_void_duplo);
 		UPDATE openmrs.obs SET voided=1     	WHERE encounter_id IN( SELECT encounter_id 
                        FROM export_db.t_void_duplo); 

 		SELECT count(*) INTO dup 
        from (SELECT patient_id, encounter_datetime, COUNT(*)
			   FROM   openmrs.encounter
			   WHERE  voided = 0 AND encounter_type = 21
			   GROUP BY 1 , 2
			   HAVING COUNT(*) >= 2 ) duplicados; 
   END WHILE;
   
SELECT patient_id, encounter_datetime, COUNT(*)
			   FROM   openmrs.encounter
			   WHERE  voided = 0 AND encounter_type = 21
			   GROUP BY 1 , 2
			   HAVING COUNT(*) >= 2;
                    
  END$$
DELIMITER ;
