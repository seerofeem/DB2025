--2.1
create view employee_details as
    select e.emp_id,e.emp_name,e.salary,d.dept_id,d.dept_name,d.location
    from employees e
    left join departments d on e.dept_id=d.dept_id
    where e.dept_id is not null;
-- 4 rows ;Tom Brown dept_is is null

--2.2
create view dept_statistics as
    select d.dept_id, d.dept_name ,count(e.emp_id) as employee_count, round(coalesce(avg(e.salary),0)::numeric,2) as avg_salary, coalesce(max(e.salary),0) as max_salary, coalesce(min(e.salary),0) as min_salary
    from departments d
    left join employees e on d.dept_id=e.dept_id
    group by d.dept_id,d.dept_name;

--2.3
create view project_overview as
    select p.project_id,p.project_name,p.budget,d.dept_id,d.dept_name,d.location,
           (select count(*)
            from employees e
            where e.dept_id=d.dept_id)
    from projects p
    left join departments d on p.dept_id=d.dept_id;

--2.4
create view high_earners as
    select e.emp_id,e.emp_name,e.salary,d.dept_name
    from employees e
    left join departments d on e.dept_id=d.dept_id
    where e.salary>55000;
--show all employees which salary>55000. if someone raised a salary,it will appear immediately-view is updated

--3.1
create view emp_details as
    select e.emp_id,e.emp_name,e.salary,d.dept_id,d.dept_name,
           case
               when e.salary>60000 then 'High'
               when e.salary>50000 then 'Medium'
               else 'Standard'
           end as salary_grade
    from employees e
    left join departments d on e.dept_id=d.dept_id;

--3.2
alter view if exists high_earners rename to top_performers;

--3.3
create temp view temp_view as
    select emp_id,emp_name, salary
    from employees
    where salary<50000;
drop view if exists temp_view;

--4.1
create view employee_salaries as
    select emp_id,emp_name,dept_id,salary
    from employees;

--4.2
update employee_salaries
set salary=52000
where emp_name='John Smith';

--4.3
insert into employee_salaries(emp_id,emp_name,dept_id,salary)
values(6,'Alice Johnson',102,58000);

--4.4
create view it_employees as
    select emp_id,emp_name,dept_id,salary
    from employees
    where dept_id=101
    with local check option;
--INSERT/UPDATE forbidden — row does not satisfy view's WITH CHECK OPTION condition

--5.1
create materialized view dept_summary as
    select d.dept_id,d.dept_name,count(e.emp_id) as total_emp,coalesce(sum(e.salary),0) as total_sal,count(p.project_id) filter (where p.project_id is not null) as total_proj,coalesce(sum(p.budget),0) as total_proj_bud
    from departments d
    left join employees e on d.dept_id=e.dept_id
    left join projects p on d.dept_id=p.dept_id
    group by d.dept_id,d.dept_name
    with data;

--5.2
insert into employees (emp_id,emp_name,dept_id,salary)
values(8,'Charlie Brown',101,54000);
refresh materialized view dept_summary;
--before refresh-shows old data, after-new data

--5.3
create unique index if not exists idx_summary on dept_summary(dept_id);
--CONCURRENTLY can be used only if MV was created WITH DATA and index exists

--5.4
create materialized view project_stats_mv as
    select p.project_id,p.project_name,p.budget,d.dept_name,
           (select count(*) from employees e where e.dept_id=p.dept_id) as assigned_employees
    from projects p
    left join departments d on p.dept_id=d.dept_id
    with no data;
refresh materialized view project_stats_mv;

--6.1
do $$
begin
    if not exists (select 1 from pg_roles where rolname='analyst') then
        create role analyst nologin;
    end if;
    if not exists (select 1 from pg_roles where rolname='data_viewer') then
        create role data_viewer login password 'viewer123';
    end if;
    if not exists (select 1 from pg_roles where rolname='report_user') then
        create role report_user login password 'report456';
    end if;
end$$;

--6.2
do $$
begin
    if not exists (select 1 from pg_roles where rolname='db_creator') then
        create role db_creator login password 'creator789' createdb;
    end if;
    if not exists (select 1 from pg_roles where rolname='user_manager') then
        create role user_manager login password 'manager101' createrole;
    end if;
    if not exists (select 1 from pg_roles where rolname='admin_user') then
        null;
    end if;
end$$;

--6.3
grant select on employees,departments,projects to analyst;
grant all privileges on employee_details to data_viewer;
grant select,insert on employees to report_user;

--6.4
do $$
begin
    if not exists(select 1 from pg_roles where rolname='hr_team') then
        create role hr_team;
    end if;
    if not exists(select 1 from pg_roles where rolname='finance_team') then
        create role finance_team;
    end if;
    if not exists(select 1 from pg_roles where rolname='it_team')then
        create role it_team;
    end if;
    if not exists (select 1 from pg_roles where rolname='hr_user1') then
        create role hr_user1 login password 'hr001';
    end if;
    if not exists(select 1 from pg_roles where rolname='hr_user2') then
        create role hr_user2 login password 'hr002';
    end if;
    if not exists (select 1 from pg_roles where rolname='finance_user1') then
        create role finance_user1 login password 'fin001';
    end if;
    grant hr_team to hr_user1;
    grant hr_team to hr_user2;
    grant finance_team to finance_user1;
    grant select,update on employees to hr_team;
    grant select on dept_statistics to finance_team;
end$$;

--6.5
revoke update on employees from hr_team;
revoke hr_team from hr_user2;
revoke all privileges on employee_details from data_viewer;

--6.6
alter role analyst with login password 'analyst123';
alter role user_manager with superuser;
alter role analyst with password null;
alter role data_viewer with connection limit 5;

--7.1
do $$
begin
    if not exists (select 1 from pg_roles where rolname='read_only') then
       create role read_only;
    end if;
    if not exists (select 1 from pg_roles where rolname='junior_analyst') then
        create role junior_analyst login password 'junior123';
    end if;
    if not exists (select 1 from pg_roles where rolname='senior_analyst') then
        create role senior_analyst login password 'senior123';
    end if;
    grant select on all tables in schema public to read_only;
    grant read_only to junior_analyst;
    grant read_only to senior_analyst;
    grant insert,update on employees to senior_analyst;
end$$;

--7.2
do $$
begin
    if not exists (select 1 from pg_roles where rolname='project_manager') then
        create role project_manager login password 'pm123';
    end if;
end$$;
alter view dept_statistics owner to project_manager;
alter table projects owner to project_manager;

--7.3
do $$
begin
    if not exists (select 1 from pg_roles where rolname='temp_owner') then
        create role temp_owner login password 'temp_pass';
    end if;
end$$;
create table if not exists temp_table(id int primary key);
alter table temp_table owner to temp_owner;
reassign owned by temp_owner to postgres;
drop owned by temp_owner;
drop role if exists temp_owner;

--7.4
create view hr_employee_view as
    select emp_id,emp_name,dept_id,salary
    from employees
    where dept_id=102;
grant select on hr_employee_view to hr_team;
drop view if exists finance_employee_view;
create view finance_employee_view as
    select emp_id,emp_name,salary
    from employees;
grant select on finance_employee_view to finance_team;

--8.1
create view dept_dashboard as
    select d.dept_id,d.dept_name,d.location,count(e.emp_id) as emp_cnt,round(coalesce(avg(e.salary),0)::numeric,2) as avg_salary,count(p.project_id) filter (where p.project_id is not null) as active_projects, coalesce(sum(p.budget),0) as total_proj_bug,
           case when count(e.emp_id)=0 then 0
                else round((coalesce(sum(p.budget),0)/count(e.emp_id))::numeric,2)
           end as budget_per_emp
    from departments d
    left join employees e on d.dept_id=e.dept_id
    left join projects p on d.dept_id=p.dept_id
    group by d.dept_id,d.dept_name,d.location;

--8.2
alter table projects add column if not exists created_date timestamp default current_timestamp;
create view high_budget_projects as
    select p.project_id,p.project_name,p.budget,d.dept_name,p.created_date,
           case
               when p.budget>150000 then 'Critical Review Required'
               when p.budget>100000 then 'Management Approval Needed'
               else 'Standard Process'
           end as approval_status
    from projects p
    left join departments d on p.dept_id=d.dept_id
    where p.budget>75000;

--8.3
do $$
begin
    if not exists (select 1 from pg_roles where rolname='viewer_role') then
        create role viewer_role;
    end if;
    if not exists (select 1 from pg_roles where rolname='entry_role') then
        create role entry_role;
    end if;
    if not exists (select 1 from pg_roles where rolname='analyst_role') then
        create role analyst_role;
    end if;
    if not exists (select 1 from pg_roles where rolname='manager_role') then
        create role manager_role;
    end if;

    if not exists (select 1 from pg_roles where rolname='alice') then
        create role alice login password 'alice123';
    end if;
    if not exists (select 1 from pg_roles where rolname='bob') then
        create role bob login password 'bob123';
    end if;
    if not exists (select 1 from pg_roles where rolname='charlie') then
        create role charlie login password 'charlie123';
    end if;
    grant viewer_role to alice;
    grant viewer_role to entry_role;
    grant entry_role to analyst_role;
    grant analyst_role to manager_role;
    revoke viewer_role from entry_role;
    grant viewer_role to entry_role;
    grant entry_role to analyst_role;
    grant analyst_role to manager_role;
    grant select on all tables in schema public to viewer_role;
    grant insert on employees,projects to entry_role;
    grant update on employees,projects to analyst_role;
    grant delete on employees,projects to manager_role;
    grant viewer_role to alice;
    grant analyst_role to bob;
    grant manager_role to charlie;
end$$;