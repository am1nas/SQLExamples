﻿/* Ispit iz Naprednih baza podataka 03.07.2021.godine*/

/*
	1. Kreiranje nove baze podataka kroz SQL kod, sa default postavkama servera  (5)
*/


create database Juli21
go
use Juli21 
go


/*
	2a. Kreiranje tabela i unošenje testnih podataka (10)

	Unutar svoje baze podataka kreirati tabele sa slijedećom strukturom:

Pacijenti
	PacijentID, automatski generator neparnih vrijednosti - primarni ključ
	JMB, polje za unos 13 UNICODE karaktera (obavezan unos) - jedinstvena vrijednost
	Prezime, polje za unos 50 UNICODE karaktera (obavezan unos)
	Ime, polje za unos 50 UNICODE karaktera (obavezan unos)
	DatumRodjenja, polje za unos datuma, DEFAULT je NULL
	DatumKreiranja, polje za unos datuma dodavanja zapisa (obavezan unos) DEFAULT je datum unosa
	DatumModifikovanja, polje za unos datuma izmjene originalnog zapisa , DEFAULT je NULL
	*/
	create table Pacijenti(
		PacijentID int identity(1,2) primary key,
		JMB nvarchar(13)not null unique,
		Prezime nvarchar(50) not null,
		Ime nvarchar(50) not null,
		DatumRodjenja datetime DEFAULT NULL,
		DatumKreiranja datetime not null DEFAULT getdate(),
		DatumModifikovanja datetime DEFAULT NULL
	)
	go
/*  Titule
	TitulaID, automatski generator vrijednosti - primarni ključ
	Naziv, polje za unos 100 UNICODE karaktera (obavezan unos)
	DatumKreiranja, polje za unos datuma dodavanja zapisa (obavezan unos) DEFAULT je datum unosa
	DatumModifikovanja, polje za unos datuma izmjene originalnog zapisa , DEFAULT je NULL
*/
	create table Titule(
		TitulaID int identity(1,1) primary key,
		Naziv nvarchar(100) not null,
		DatumKreiranja datetime not null DEFAULT getdate(),
		DatumModifikovanja datetime DEFAULT NULL
	)
	go

/*
Osoblje (Jednu titulu može imati više osoba)
	OsobljeID, automatski generator vrijednosti i primarni kljuè
	Prezime, polje za unos 50 UNICODE karaktera (obavezan unos)
	Ime, polje za unos 50 UNICODE karaktera (obavezan unos)
	DatumKreiranja, polje za unos datuma dodavanja zapisa (obavezan unos) DEFAULT je datum unosa
	DatumModifikovanja, polje za unos datuma izmjene originalnog zapisa , DEFAULT je NULL
	*/
	create table Osoblje(
		OsobljeID int  identity(1,1) primary key,
		Prezime nvarchar(50) not null,
		Ime nvarchar(50) not null,
		DatumKreiranja datetime not null DEFAULT getdate(),
		DatumModifikovanja datetime DEFAULT NULL
	)
	go
	alter table Osoblje
	add TitulaID int,
	constraint FK_Osoblje_Titule foreign key(TitulaID) references Titule(TitulaID)
	go
/*

Pregledi (Pacijent može izvršiti samo jedan pregled kod istog doktora unutar termina)
	PregledID, polje za unos cijelih brojeva (obavezan unos)
	DatumPregleda, polje za unos datuma (obavezan unos) DEFAULT je datum unosa
	Dijagnoza polje za unos 1000 UNICODE karaktera (obavezan unos)
*/
create table Pregledi(
	PregledID int not null primary key,
	DatumPregleda datetime not null DEFAULT getdate(),
	Dijagnoza nvarchar(1000) not null,
	PacijentID int foreign key references Pacijenti(PacijentID),
	OsobljeID int foreign key references Osoblje(OsobljeID)
)
go




/*
		2b. Izmjena tabele "Pregledi" (5)

Modifikovati tabelu Pregledi i dodati dvije kolone:
DatumKreiranja, polje za unos datuma dodavanja zapisa (obavezan unos) DEFAULT je datum unosa
DatumModifikovanja, polje za unos datuma izmjene originalnog zapisa , DEFAULT je NULL
*/

alter table Pregledi
add DatumKreiranja datetime not null default getdate(),
	DatumModifikovanja datetime default null
go
select * from Pregledi
go


/*
		2c. Unošenje testnih podataka (10)

Iz baze podataka Northwind, a putem podupita dodati sve zapise iz tabele Employees:
(LastName, FirstName, BirthDate) u tabelu Pacijenti. Za JMB koristiti SQL funkciju koja
generiše slučajne i jedinstvene ID vrijednosti. Obavezno testirati da li su podaci u tabeli.
*/
insert into Pacijenti(Prezime, Ime, DatumRodjenja, JMB)
select LastName, FirstName, BirthDate, LEFT(CONVERT(nvarchar(36), newid()),13) as JMB
from NORTHWND.dbo.Employees
go
select * from Pacijenti
go
/*
U tabelu Titule, jednom komandom, dodati: Stomatolog, Oftalmolog, Ginekolog,
Pulmolog i Onkolog. Obavezno testirati da li su podaci u tabeli.
*/
insert into Titule(Naziv)
values ('Stomatolog'),
	   ('Oftalmolog'),
	   ('Ginekolog'),
	   ('Pulmolog'),
	   ('Onkolog')
go
select * from Titule
go
/*
U tabelu Osoblje, jednom komandom, dodati proizvoljna dva zapisa. 
Obavezno testirati da li su podaci u tabeli.

*/
insert into Osoblje(Prezime, Ime, TitulaID)
values ('Azemovic', 'Jasmin', 1),
		('Begic', 'Jasmin', 1)
go
select * from Osoblje
go

/*
	2d. Kreirati uskladištenu proceduru (10) 

U tabelu Pregledi dodati 4 zapisa proizvoljnog karaktera. Obavezno testirati da li su podaci u tabeli.
*/
create or alter proc UnosPregledi as
begin
	insert into Pregledi(PregledID,Dijagnoza, PacijentID, OsobljeID)
	values (1,'Bol u umnjaku',1,1), (2,'Operacija umnjaka',3,1),
	(3,'Bol u umnjaku',5,1), (4,'Operacija umnjaka',3,2)
end
go

exec UnosPregledi
go
select * from Pregledi
go

/*
	3. Kreiranje procedure za izmjenu podataka u tabeli "Pregledi" (10)

Koja će izvršiti izmjenu podataka u tabeli Pregledi, tako što će modifikovati dijagnoza za određeni pregled. 
Također, potrebno je izmjeniti vrijednost još jednog atributa u tabeli kako bi zapis o poslovnom procesu
bio potpun. Obavezno testirati da li su podaci u tabeli modifikovani
*/
create or alter proc IzmjenaPregledi 
	@dijagnoza nvarchar(1000),
	@pregledID int
	as 
begin
	update Pregledi
	set Dijagnoza=@dijagnoza,
		DatumModifikovanja = GETDATE()
	where PregledID=@pregledID
end
go
exec IzmjenaPregledi 'ispala plomba', 1
select * from Pregledi
go




/*
	4. Kreiranje pogleda (5)

Kreirati pogled sa slijedećom definicijom: Prezime i ime pacijenta, datum pregleda, titulu, prezime i ime
doktora, dijagnozu i datum zadnje izmjene zapisa, ali samo onim pacijentima kojima je modfikovana
dijagnoza. Obavezno testirati funkcionalnost view objekta.

*/
create or alter view view_info as
select p.Prezime+' '+p.Ime as Pacijent, pr.DatumPregleda, t.Naziv, o.Prezime + ' ' + o.Ime as Doktor, pr.Dijagnoza, pr.DatumModifikovanja
from Pacijenti p join Pregledi pr on p.PacijentID=pr.PacijentID
join Osoblje o on pr.OsobljeID=o.OsobljeID
join Titule t on t.TitulaID=o.TitulaID
where pr.DatumModifikovanja is not null
go
select * from view_info
go

/* GRANICA ZA OCJENU 6 (55 bodova) */



/*
	5. Prilagodjavanje tabele "Pacijenti" (5)

Modifikovati tabelu Pacijenti i dodati slijedeće tri kolone:
	Email, polje za unos 100 UNICODE karaktera, DEFAULT je NULL
	Lozinka, polje za unos 100 UNICODE karaktera, DEFAULT je NULL
	Telefon, polje za unos 100 UNICODE karaktera, DEFAULT je NUL
*/

alter table Pacijenti
add Email nvarchar(100) default null,
	Lozinka nvarchar(100) default null,
	Telefon nvarchar(100) default null
go
select * from Pacijenti
go
/*
	6. Dodavanje dodatnih zapisa u tabelu "Pacijenti" (5)

Kreirati uskladištenu proceduru koja će iz baze podataka AdventureWorks i tabela:
Person.Person, HumanResources.Employee, Person.Password, Person.EmailAddress i
Person.PersonPhone mapirati odgovarajuće kolone i prebaciti sve zapise u tabelu Pacijenti.
Obavezno testirati da li su podaci u tabeli

*/
select top 3 * from AdventureWorks2017.Person.Person
select top 3 * from AdventureWorks2017.HumanResources.Employee
select top 3 * from AdventureWorks2017.Person.Password
select top 3 * from AdventureWorks2017.Person.EmailAddress
select top 3 * from AdventureWorks2017.Person.PersonPhone
go
create or alter proc DodavanjePacijenti as
begin
	set identity_insert Pacijenti on
	insert into Pacijenti(PacijentID, JMB, Prezime, Ime, DatumRodjenja, Email, Lozinka, Telefon)
	select p.BusinessEntityID, LEFT(p.rowguid, 13), p.LastName, p.FirstName, e.BirthDate, ea.EmailAddress ,pass.PasswordHash, pp.PhoneNumber 
	from AdventureWorks2017.Person.Person p join AdventureWorks2017.HumanResources.Employee e on p.BusinessEntityID=e.BusinessEntityID
		join AdventureWorks2017.Person.Password pass on p.BusinessEntityID=pass.BusinessEntityID
		join AdventureWorks2017.Person.EmailAddress ea on p.BusinessEntityID=ea.BusinessEntityID
		join AdventureWorks2017.Person.PersonPhone pp on p.BusinessEntityID=pp.BusinessEntityID
		set identity_insert Pacijenti off
end
go
delete from Pregledi
delete from Pacijenti

exec DodavanjePacijenti
go
select * from Pacijenti



/*
	7. Izmjena podataka u tabel "Pacijenti" (10)

Kreirati uskladištenu proceduru koja će u vašoj bazi podataka, svim pacijentima generisati novu email
adresu u formatu: Ime.Prezime@size.ba, lozinku od 12 karaktera putem SQL funkciju koja generiše
slučajne i jedinstvene ID vrijednosti i podatak da je postojeći zapis u tabeli modifikovan.
*/
go
create or alter proc IzmjenaPacijenti as
begin
	update Pacijenti
	set Email= Ime+'.'+Prezime+'@size.ba',
		Lozinka = LEFT(CONVERT(nvarchar(36), newid()), 12),
		DatumModifikovanja = GETDATE()
end
go
exec IzmjenaPacijenti
go
select * from Pacijenti
go


/*
	8. Kriranje upita i indeksa (5)

Napisati upit koji prikazuje prezime i ime pacijenta, datum pregleda, dijagnozu i spojene podatke o
doktoru (titula, prezime i ime doktora). U obzir dolaze samo oni pacijenti koji imaju dijagnozu ili čija
email adresa počinje sa slovom „L“. 
Nakon toga kreirati indeks koji će prethodni upit, prema vašem mišljenju, maksimalno ubrzati
*/
select * from Pregledi
go
select p.Prezime+' '+p.Ime as Pacijent, pr.DatumPregleda, pr.Dijagnoza, t.Naziv , o.Prezime +' '+ o.Ime as Doktor
from Pacijenti p join Pregledi pr on p.PacijentID=pr.PacijentID
join Osoblje o on pr.OsobljeID=o.OsobljeID
join Titule t on o.TitulaID = t.TitulaID
where pr.Dijagnoza is not null or p.Email like 'L%'

create nonclustered index ix_pacijenti_email_id
on Pacijenti(PacijentID, Email)


/*
	9. Brisanje pacijenata bez pregleda (5)

Kreirati uskladištenu proceduru koja briše sve pacijente koji nemaju realizovan niti jedan pregled.
Obavezno testirati funkcionalnost procedure. 
*/go
create or alter proc BisanjePregleda as
begin
delete from Pacijenti where PacijentID not in (select distinct PacijentID from Pregledi)
end
go
exec BisanjePregleda
select * from Pacijenti
select * from Pregledi

/*
	10a. Backup baze podataka (5)
Kreirati backup vaše baze na default lokaciju servera	
*/

backup database Juli21
to disk='C:\BackupSQL\Juli21.bak'

/*
	10b. Brisanje svih zapisa iz tabela (5)
Kreirati proceduru koja briše sve zapise iz svih tabela unutar jednog izvršenja. Testirati da li su podaci
obrisani	
*/
go
create or alter proc BrisanjeSve as 
begin
	delete from Pregledi
	delete from Osoblje
	delete from Titule
	delete from Pacijenti
end
go
exec BrisanjeSve
go
select COUNT(*) from Pregledi
select COUNT(*)	from Osoblje
select COUNT(*)	from Titule
select COUNT(*)	from Pacijenti
/*
	10c. Restore baze podataka (5)
Uraditi restore rezervene kopije baze podataka 
*/

use master
go
restore database Juli21 from disk='C:\BackupSQL\Juli21.bak' with replace