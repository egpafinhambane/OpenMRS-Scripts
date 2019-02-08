-- Fluxo de registo pre-tarv
-- cocept 6263  - Livro 1  value_coded 6259
-- 				- Livro 2  value_coded 6220
-- paramentros para teste
set @startDate := '2018-09-21 00:00:00';
set @endDate := '2018-12-20 00:00:00';
set @location := 212; -- location de uma us de inhambane

select *
      from
			(select 
                inicio_real.patient_id,
				pid.identifier as NID,
                concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',				
				p.gender,
				round(datediff( @endDate,p.birthdate)/365) as idade_actual,
                pad3.county_district as 'Distrito',
				pad3.address2 as 'PAdministrativo',
				pad3.address6 as 'Localidade',
				pad3.address5 as 'Bairro',
				pad3.address1 as 'PontoReferencia',
				inicio_real.data_inicio,
                if(programa_pre_tarv.patient_id is null,'NAO','SIM') registado_progr_pre_tarv,
                if(programa_tarv.patient_id is null,'NAO','SIM') registado_progr_tarv,
                if(inicio_tarv.patient_id is null,'NAO','SIM') iniciou_tarv,
                saida.encounter_datetime as data_saida,
				saida.estado as tipo_saida
				
				
			from	
			    (select patient_id,data_inicio
				 from
				    (select patient_id,min(data_inicio) data_inicio
					 from  -- Inscricao no livro pre-tarv
					    ( select 	p.patient_id,min(e.encounter_datetime) data_inicio
				          from 	patient p 
						  inner join encounter e on p.patient_id=e.patient_id	
						  inner join obs o on o.encounter_id=e.encounter_id
				          where 	e.voided=0 and o.voided=0 and p.voided=0 and 
						  e.encounter_type =32 and o.concept_id=6263 and o.value_coded in (6259,6260) and 
						  e.encounter_datetime<=@endDate and e.location_id=@location
						  group by p.patient_id
                          
					     -- union
						 -- Programa tarv cuidado
						 -- select 	pg.patient_id,date_enrolled data_inicio
						 -- from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
						 -- where 	pg.voided=0 and p.voided=0 and program_id=1 and date_enrolled<=@endDate and location_id=@location
				        ) inicio
		group by patient_id	
	)inicio1
where data_inicio between @startDate and @endDate
)inicio_real
	inner join person p on p.person_id=inicio_real.patient_id
			inner join
			(
				select 	p.patient_id 
				from 	patient p inner join encounter e on e.patient_id=p.patient_id 
				where 	e.voided=0 and p.voided=0 and e.encounter_type in (5,7) and e.encounter_datetime<=@endDate and e.location_id = @location

				union

				select 	pg.patient_id
				from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
				where 	pg.voided=0 and p.voided=0 and program_id=1 and date_enrolled<=@endDate and location_id=@location
			)inscricao on inicio_real.patient_id=inscricao.patient_id			
			left join 
			(	select pad1.*
				from person_address pad1
				inner join 
				(
					select person_id,min(person_address_id) id 
					from person_address
					where voided=0
					group by person_id
				) pad2
				where pad1.person_id=pad2.person_id and pad1.person_address_id=pad2.id
			) pad3 on pad3.person_id=inicio_real.patient_id				
			left join 			
			(	select pn1.*
				from person_name pn1
				inner join 
				(
					select person_id,min(person_name_id) id 
					from person_name
					where voided=0
					group by person_id
				) pn2
				where pn1.person_id=pn2.person_id and pn1.person_name_id=pn2.id
			) pn on pn.person_id=inicio_real.patient_id			
			left join
			(       select pid1.*
					from patient_identifier pid1
					inner join
									(
													select patient_id,min(patient_identifier_id) id
													from patient_identifier
													where voided=0
													group by patient_id
									) pid2
					where pid1.patient_id=pid2.patient_id and pid1.patient_identifier_id=pid2.id
			) pid on pid.patient_id=inicio_real.patient_id	
            
             -- INICIOU Programa TARV
             left join
            (
            	Select 	p.patient_id,min(value_datetime) data_inicio
 				from 	patient p
 						inner join encounter e on p.patient_id=e.patient_id
 						inner join obs o on e.encounter_id=o.encounter_id
 				where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (18,6,9) and 
 						o.concept_id=1190 and o.value_datetime is not null and 
 						o.value_datetime<=@endDate and e.location_id=@location
 				group by p.patient_id) inicio_tarv on inicio_tarv.patient_id=inicio_real.patient_id
		     left join
			(
				select 	pg.patient_id
				from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
				where 	pg.voided=0 and p.voided=0 and program_id=1 and date_enrolled<=@endDate and location_id=@location
			) programa_pre_tarv on programa_pre_tarv.patient_id=inicio_real.patient_id
			 left join
			(
				select 	pg.patient_id
				from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
				where 	pg.voided=0 and p.voided=0 and program_id=2 and date_enrolled<=@endDate and location_id=@location
			) programa_tarv on programa_tarv.patient_id=inicio_real.patient_id
            	
			 left join
			(		
				select 	pg.patient_id,ps.start_date encounter_datetime,location_id,
						case ps.state
							when 7 then 'TRANSFERIDO PARA'
							when 8 then 'SUSPENSO'
							when 9 then 'ABANDONO'
							when 10 then 'OBITO'
						else 'OUTRO' end as estado
				from 	patient p 
						inner join patient_program pg on p.patient_id=pg.patient_id
						inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
				where 	pg.voided=0 and ps.voided=0 and p.voided=0 and  pg.program_id=1
						and ps.state in (7,8,9,10) and ps.end_date is null and location_id=@location	
			
			) saida on saida.patient_id=inicio_real.patient_id

)inicios  where registado_progr_tarv ='NAO'
group by patient_id
