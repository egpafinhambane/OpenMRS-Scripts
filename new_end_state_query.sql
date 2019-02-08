
select * from
   (
	SELECT pp.patient_program_id,pp.patient_id,
       ps.state,pws.concept_id, pp.date_enrolled,pp.date_completed,ps.start_date, 
       ps.end_date
--     ,cn.concept_id, initial,terminal,cn.name

FROM hrv.patient_state ps 
 inner join hrv.patient_program pp on pp.patient_program_id = ps.patient_program_id
 inner join hrv.program_workflow_state pws on pws.program_workflow_state_id = ps.state
 -- inner join hrv.concept_name cn on cn.concept_id = pws.concept_id
and pp.program_id=1 ) pre_tarv 
left join
(
SELECT  pg_wfs.concept_id,
		cn.name
FROM hrv.program_workflow pg_wf 
inner join hrv.program_workflow_state pg_wfs ON pg_wfs.program_workflow_id = pg_wf.program_workflow_id
inner join hrv.concept_name cn on cn.concept_id = pg_wfs.concept_id

and pg_wf.program_id=1 and name in ('ACTIVO NO PROGRAMA','ABANDONO','TRANSFERIDO PARA','INICIAR','OBITOU',
'TRANSFERIDO DE') ) estado_saida on estado_saida.concept_id=pre_tarv.concept_id
group by patient_id,estado_saida.concept_id,name
order by patient_id, FIELD(name, 'ACTIVO NO PROGRAMA' , 'INICIAR', 'ABANDONO','OBITOU')

-- estados
-- 6269 : activo pre-tarv ** Inicial
-- 1707 : Abandono
-- 1706 : Transferido para
-- 1256 : Iniciar         ** Final
-- 1366 : Obito
-- 1369 : Transferido de  ** Inicial
