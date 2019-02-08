SELECT pp.patient_program_id,pp.patient_id, pp.program_id,ps.patient_state_id,
       ps.state,pws.concept_id, pp.date_enrolled,pp.date_completed,ps.start_date, 
       pp.location_id ,ps.end_date, pws.program_workflow_id
--     ,  cn.concept_id, initial,terminal,cn.name

FROM hrv.patient_state ps 
 inner join hrv.patient_program pp on pp.patient_program_id = ps.patient_program_id
 inner join hrv.program_workflow_state pws on pws.program_workflow_state_id = ps.state
 -- inner join hrv.concept_name cn on cn.concept_id = pws.concept_id
and pp.program_id=1;



-- estados
-- 6269 : activo pre-tarv ** Inicial
-- 1707 : Abandono
-- 1706 : Transferido para
-- 1256 : Iniciar         ** Final
-- 1366 : Obito
-- 1369 : Transferido de  ** Inicial
