-- GROUP ROLES AND TABLE PERMISSIONS --

create role vet;
create role vettech;
create role admin;

GRANT SELECT ON appttype TO vet, vettech, admin;
GRANT SELECT ON breedspecies TO vet, vettech, admin;
GRANT SELECT ON breedissues TO vet, vettech, admin;
GRANT SELECT, UPDATE, INSERT ON diagnosis TO vet, vettech;
GRANT SELECT ON diagnosis TO admin;
GRANT SELECT ON diagnosticlookup TO vet, vettech, admin;
GRANT SELECT ON medication TO vet, vettech, admin;
GRANT SELECT ON owner TO vet, vettech;
GRANT SELECT, UPDATE, INSERT, DELETE ON owner TO admin;
GRANT SELECT, UPDATE, INSERT, DELETE ON pet TO vet, vettech, admin;
GRANT SELECT ON pet_has_owner TO vet, vettech;
GRANT SELECT, UPDATE, INSERT, DELETE ON pet_has_owner TO admin;
GRANT SELECT, UPDATE, INSERT ON prescription TO vet;
GRANT SELECT ON prescription TO vettech, admin;
GRANT SELECT, UPDATE, INSERT, DELETE ON procedure TO vet, vettech, admin;
GRANT SELECT ON procedurelookup TO vet, vettech, admin;
GRANT SELECT, UPDATE, INSERT, DELETE ON visit TO admin;
GRANT SELECT, UPDATE ON visit TO vet, vettech;
GRANT SELECT, UPDATE, INSERT, DELETE ON appointment TO admin;
GRANT SELECT, UPDATE, INSERT, DELETE ON billing TO admin;
GRANT SELECT, UPDATE, INSERT, DELETE ON payment TO admin;
GRANT SELECT, UPDATE, INSERT, DELETE ON insprovider TO admin;
GRANT SELECT, UPDATE, INSERT, DELETE ON account TO admin;


-- FUNCTIONS --

-- UPDATE VISIT RECORD --

CREATE FUNCTION updaterecords(
	today date,
	petname varchar,
	ownerfirst varchar,
	ownerlast varchar,
	proceduretype_id int,
	diagnosistype_id int,
	followupreq varchar,
	followupdate date)
RETURNS int
AS '
DECLARE thisvisitid int := 0;
		petid int := 0;
BEGIN
insert into visit 
(appointment_id)
select a.appointment_id
from appointment a
join pet p on a.pet_id = p.pet_id
join pet_has_owner pho on p.pet_id = pho.pet_id
join owner o on pho.owner_id = o.owner_id
where p.petname = $2 AND o.firstname = $3 AND o.lastname = $4 AND a.appt_date = $1;

petid := (select p.pet_id from pet p
			join pet_has_owner pho on p.pet_id = pho.pet_id
			join owner o on pho.owner_id = o.owner_id
		 	where p.petname = $2 and o.lastname = $4);
thisvisitid := max(visit_id) from visit;

IF $5 is not null THEN
insert into procedure --will work even if procedure_id in param is null
(procedure_id, visit_id, proceduretype_id) 
select (max(p.procedure_id) + 1),
	thisvisitid,
	$5
from procedure p
join visit v on thisvisitid = v.visit_id
left outer join appointment a on v.appointment_id = a.appointment_id
join appttype at on a.appttype_id = at.appttype_id;
END IF;
--needs conditional: done

IF $6 is not null THEN
insert into diagnosis
(diagnosis_id, visit_id, diagnosticlookup_id)
select (max(d.diagnosis_id) + 1),
	thisvisitid,
	$6
from diagnosis d;
END IF;
--needs conditional: done

update visit
set followup_req = $7
where visit_id = thisvisitid;
--already conditional enough

update visit
set followupdate = $8
where visit_id = thisvisitid AND followup_req = $$Y$$;
--already conditional enough

IF $7 = $$Y$$ THEN
insert into appointment
(appointment_id, appt_date, pet_id, appttype_id)
select (max(appointment_id) + 1),
	$8,
	petid,
	4
from appointment;
END IF;
--if $7 = $$Y$$ ONLY

RETURN thisvisitid;
END;'
LANGUAGE plpgsql;


-- CALL UP RECOMMENDED TREATMENT BASED ON BREED --

CREATE FUNCTION breedtreat(petname varchar, ownerlast varchar)
RETURNS TABLE (petname varchar, lastname varchar, pet_type varchar, breed varchar, health_issue varchar)
AS '
select p.petname, o.lastname as "owner name", bs.generictype, bs.breedname, bi.health_issue_desc
from breedissues bi
join breedspecies bs on bi.breedspecies_id = bs.breedspecies_id
join pet p on bi.breedspecies_id = p.breedspecies_id
join pet_has_owner pho on p.pet_id = pho.pet_id
join owner o on o.owner_id = pho.owner_id
where p.petname = $1 and o.lastname = $2;'
LANGUAGE SQL;


-- FIND ALL OWNERS FOR PET --

CREATE FUNCTION findownerpet(petname varchar)
RETURNS TABLE (petname varchar, breed varchar, firstname varchar, lastname varchar, street varchar, city varchar, state char, phone varchar)
AS '
select p.petname, bs.breedname, o.firstname, o.lastname, o.street_ad, o.city, o.state, o.phone
from owner o
join pet_has_owner pho on o.owner_id = pho.owner_id
join pet p on p.pet_id = pho.pet_id
join breedspecies bs on p.breedspecies_id = bs.breedspecies_id
where p.petname = $1;'
LANGUAGE SQL;


-- SEND ORDER TO PHARMACY --

CREATE FUNCTION ordermed(petname varchar, medname varchar)
RETURNS TABLE (petname varchar, medname varchar, use_text varchar, warn_text varchar,
	dose double precision, units varchar, cost double precision)
AS '
select p.petname, 
	m.medname, 
	m.use_text, 
	m.warn_text, 
	p.weight*m.perkg_dose as "dose",
	m.units, 
	p.weight*m.perkg_dose*dose_cost as "cost"  
from pet p 
join appointment a on p.pet_id = a.pet_id
join visit v on a.appointment_id = v.appointment_id
join diagnosis d on v.visit_id = d.visit_id
join prescription rx on d.diagnosis_id = rx.diagnosis_id
join medication m on rx.med_id = m.med_id
where p.petname = $1 AND m.medname = $2 AND a.appt_date = now()::date;'
LANGUAGE SQL;


-- PROMPT CONFIRMATION CALL --

CREATE FUNCTION promptcall(today date, intervaldays int)
RETURNS TABLE (petname varchar,
	firstname varchar, 
	lastname varchar, 
	phone varchar, 
	appt_date date, 
	appt_type varchar)
AS '
select p.petname, o.firstname, o.lastname, o.phone, a.appt_date, at.appttypename
from pet p
join pet_has_owner pho on p.pet_id = pho.pet_id
join owner o on pho.owner_id = o.owner_id
join appointment a on p.pet_id = a.pet_id
join appttype at on a.appttype_id = at.appttype_id
where a.appt_date = $1 + $2;'
LANGUAGE SQL;


-- CALCULATE AND CREATE BILL -----------------------------------------------
-- there are four different functions to support this application

-- RETRIEVE BILL LINES FOR PROCEDURES --

CREATE FUNCTION retrieve_procedure_bill_lines(startdate date, enddate date)
RETURNS TABLE (visit_id integer,
	appt_date date,
	duedate date, 
	petname varchar, 
	bill_amount numeric,
	procedure_id integer,
	procedurename varchar, 
	coveredby varchar,
	owner_id integer,
	firstname varchar,
	lastname varchar,
	insureprov_id integer,
	insurename varchar)
AS '
select vis.visit_id, app.appt_date, (app.appt_date + 90) as duedate, pet.petname, prol.proccost as bill_amount,
pro.procedure_id, prol.procedurename, prol.coveredby, own.owner_id, own.firstname, own.lastname,
ip.insureprov_id, ip.insurename
from procedure pro
join visit vis on vis.visit_id = pro.visit_id
join appointment app on app.appointment_id = vis.appointment_id
join procedurelookup prol on prol.proceduretype_id = pro.proceduretype_id
join pet pet on pet.pet_id = app.pet_id
join pet_has_owner pho on pho.pet_id = pet.pet_id
join owner own on own.owner_id = pho.owner_id
join insprovider ip on ip.insureprov_id = own.insureprov_id
where app.appt_date >= $1 and app.appt_date <= $2
order by vis.visit_id'
LANGUAGE SQL;


-- RETRIEVE BILL LINES FOR PRESCRIPTIONS --

CREATE FUNCTION retrieve_prescription_bill_lines(startdate date, enddate date)
RETURNS TABLE (visit_id integer,
	appt_date date,
	duedate date, 
	petname varchar, 
	bill_amount double precision,
	prescription_id integer,
	medname varchar, 
	coveredby varchar,
	owner_id integer,
	firstname varchar,
	lastname varchar,
	insureprov_id integer,
	insurename varchar)
AS '
select vis.visit_id, app.appt_date, (app.appt_date + 90) as duedate, pet.petname,
(med.perkg_dose * med.dose_cost * pet.weight) as bill_amount, pre.prescription_id, med.medname,
med.coveredby, own.owner_id, own.firstname, own.lastname, ip.insureprov_id, ip.insurename
from prescription pre
join medication med on med.med_id = pre.med_id
join diagnosis dia on dia.diagnosis_id = pre.diagnosis_id
join visit vis on vis.visit_id = dia.visit_id
join appointment app on app.appointment_id = vis.appointment_id
join pet pet on pet.pet_id = app.pet_id
join pet_has_owner pho on pho.pet_id = pet.pet_id
join owner own on own.owner_id = pho.owner_id
join insprovider ip on ip.insureprov_id = own.insureprov_id
where app.appt_date >= $1 and app.appt_date <= $2
order by vis.visit_id'
LANGUAGE SQL;


-- INSERT NEW BILLING LINE --

CREATE FUNCTION insert_bill_line(visit_id integer, insureprov_id integer,
owner_id integer, duedate date, billamount numeric, remainderdue numeric)
RETURNS void AS
        'INSERT INTO billing(bill_id, visit_id, insureprov_id, owner_id, duedate, billamount, remainderdue)
        SELECT(max(bill_id) +1), $1, $2, $3, $4, $5, $6 from billing'
LANGUAGE SQL;


-- UPDATE ACCOUNT TABLE --

CREATE FUNCTION bill_to_account(bill_amount numeric, insureprov_id integer, owner_id integer)
RETURNS void AS
	'UPDATE account
	SET acct_bal = acct_bal::numeric - $1
	WHERE insureprov_id = $2 or owner_id = $3'
LANGUAGE SQL;

--------------------------------------------------------------------------------------------


-- PROCESS PAYMENT --

CREATE FUNCTION process_payment(amount numeric, bill_id integer)
RETURNS void AS
'BEGIN
	INSERT INTO payment(payment_id, amount, bill_id)
	SELECT(max(payment_id)+1), $1, $2 from payment;

	UPDATE billing
	SET remainderdue = remainderdue::numeric - $1
	WHERE billing.bill_id = $2;

	UPDATE account
	SET acct_bal = acct_bal::numeric + $1
	WHERE account.insureprov_id = (select billing.insureprov_id from billing where billing.bill_id = $2)
	OR account.owner_id = (select billing.owner_id from billing where billing.bill_id = $2);	
END'
LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------


-- MAKE AND INPUT NEW APPOINTMENT -----------------------------------------------
-- there are four different functions to support this application

-- MAKE NEW APPOINTMENT --

CREATE FUNCTION make_new_appointment
(petname varchar, appttypename varchar, appt_date date)
RETURNS void AS
        'INSERT INTO appointment(appointment_id, pet_id, appttype_id, appt_date)
        SELECT (max(appointment_id)+1), (select pet_id from pet where pet.petname = $1),
        (select appttype_id from appttype where appttype.appttypename = $2), $3 from appointment'
LANGUAGE SQL;


-- ADD NEW PET TO THE DATABASE --

CREATE FUNCTION add_new_pet
(petname varchar, breedname varchar, weight integer, dob date)
RETURNS void AS
        'INSERT INTO pet(pet_id, petname, breedspecies_id, weight, dob)
        SELECT(max(pet_id)+1), $1,
        (select breedspecies_id from breedspecies where breedspecies.breedname = $2), $3, $4 from pet'
LANGUAGE SQL;


-- ADD NEW OWNER TO THE DATABASE --

CREATE FUNCTION add_new_owner
(firstname varchar, lastname varchar, street_ad varchar, city varchar,
state char, phone varchar, zip varchar, credit_card_no char, cc_exp date, insurename varchar)
RETURNS void AS
        'INSERT INTO owner(owner_id, firstname, lastname, street_ad, city,
        state, phone, zip, credit_card_no, cc_exp, insureprov_id)
        SELECT (max(owner_id)+1), $1, $2, $3, $4, $5, $6, $7, $8, $9,
        (select insureprov_id from insprovider where insprovider.insurename = $10) from owner'
LANGUAGE SQL;


-- ADD PET/OWNER RELATIONSHIP TO THE DATABASE

CREATE FUNCTION add_pet_owner_link
(petname varchar, firstname varchar, lastname varchar)
RETURNS void AS
        'INSERT INTO pet_has_owner(pet_id, owner_id)
        VALUES((select pet_id from pet where pet.petname = $1),
	(select owner_id from owner where owner.firstname = $2 and owner.lastname = $3))'
LANGUAGE SQL;

----------------------------------------------------------------------------------------


-- REVIEW OVERDUE BILLS --

CREATE FUNCTION review_overdue_bills
(checkdate date, owner_first varchar, owner_last varchar, insurename varchar)
RETURNS TABLE (duedate date,
	bill_id integer,
	billamount money, 
	remainderdue money, 
	owner_id integer,
	firstname varchar,
	lastname varchar,
	insureprov_id integer,
	insurename varchar)
AS
'select b.duedate, b.bill_id, b.billamount, b.remainderdue,
b.owner_id, o.firstname, o.lastname, b.insureprov_id, i.insurename
from billing b
left outer join owner o on o.owner_id = b.owner_id
left outer join insprovider i on i.insureprov_id = b.insureprov_id
where b.remainderdue > 0::money and b.duedate < $1
and ((o.firstname = $2 and o.lastname = $3) or (i.insurename = $4))
order by bill_id'
LANGUAGE SQL;

-----------------------------------------------------------------------------------------


-- FIND PROFIT / LOSS FOR PERIOD -----------------------------------------------
-- there are two different functions to support this application

-- DETAILED PROFIT OR LOSS REPORT (provides all bills and payments in a specified period)

CREATE FUNCTION detailed_profit_or_loss
(startdate date, enddate date)
RETURNS TABLE (bill_id integer,
	issue_date date, 
	duedate date, 
	billamount money,
	remainderdue money,
	payment money,
	insurename varchar,
	owner_first varchar,
	owner_last varchar)
AS
'select b.bill_id, a.appt_date as issue_date, b.duedate, b.billamount, b.remainderdue, p.amount as payment,
i.insurename, o.firstname as owner_first, o.lastname as owner_last
from billing b
left outer join payment p on p.bill_id = b.bill_id
left outer join insprovider i on i.insureprov_id = b.insureprov_id
left outer join owner o on o.owner_id = b.owner_id
join visit v on v.visit_id = b.visit_id
join appointment a on a.appointment_id = v.appointment_id
where a.appt_date >= $1 and a.appt_date <= $2
order by b.duedate, b.bill_id'
LANGUAGE SQL;


-- BOTTOM-LINE PROFIT OR LOSS REPORT (provides a single summation of all open bill items) --
-- (note: due to the demonstration nature of the database, this isn'e a true profit as the data
-- does not include a profit-margin.  However it demonstrates tracking of income and outgoings.

CREATE FUNCTION bottom_line_profit_or_loss
(startdate date, enddate date)
RETURNS TABLE (profit_or_loss money)
AS
'select ((sum (b.remainderdue)) * -1) as profit_or_loss
from billing b
join visit v on v.visit_id = b.visit_id
join appointment a on a.appointment_id = v.appointment_id
where a.appt_date >= $1 and a.appt_date <= $2'
LANGUAGE SQL;