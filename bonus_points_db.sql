set client_min_messages = warning;

create schema if not exists bank_async;
set search_path = bank_async, public;

create table customers (
    customer_id serial primary key,
    iin varchar(12) unique not null,
    full_name text not null,
    phone varchar(20),
    email text,
    status varchar(16) default 'active',
    created_at timestamptz default now(),
    daily_limit_kzt numeric(18,2) default 5000000
);

create table accounts (
    account_id serial primary key,
    customer_id int not null references customers(customer_id),
    account_number varchar(40) unique not null,
    currency varchar(3) not null,
    balance numeric(22,2) default 0,
    is_active boolean default true,
    opened_at timestamptz default now(),
    closed_at timestamptz
);

create table exchange_rates (
    rate_id serial primary key,
    from_curr varchar(3) not null,
    to_curr varchar(3) not null,
    rate_value numeric(28,10) not null,
    valid_from timestamptz default now(),
    valid_until timestamptz
);

create table ledger (
    trans_id serial primary key,
    src_acc int references accounts(account_id),
    dst_acc int references accounts(account_id),
    amt_raw numeric(22,2) not null,
    curr_raw varchar(3) not null,
    applied_rate numeric(28,10),
    amt_kzt numeric(22,2),
    event_kind varchar(20) not null,
    event_status varchar(20) default 'pending',
    created_at timestamptz default now(),
    finished_at timestamptz,
    note text
);

create table audit_events (
    event_id serial primary key,
    entity_name text,
    entity_id text,
    event_type text,
    before_state jsonb,
    after_state jsonb,
    actor text,
    happened_at timestamptz default now(),
    ip_addr inet
);

insert into customers(iin, full_name, phone, email, status, daily_limit_kzt) 
values
('880101000001','aruzhan n','+77010000001','a@ex.com','active',1000),
('900202000002','daniyar k','+77010000002','d@ex.com','active',8000000),
('910303000003','nurgul s','+77010000003','n@ex.com','active',5000000),
('920404000004','bekzat t','+77010000004','b@ex.com','blocked',2000000),
('930505000005','laila m','+77010000005','l@ex.com','frozen',3000000),
('940606000006','erlan z','+77010000006','e@ex.com','active',7000000),
('950707000007','aigerim o','+77010000007','ai@ex.com','active',6000000),
('960808000008','ruslan p','+77010000008','r@ex.com','active',15000000),
('970909000009','zhanar b','+77010000009','z@ex.com','active',4000000),
('981010000010','maksat h','+77010000010','m@ex.com','active',12000000);

insert into accounts(customer_id, account_number, currency, balance) 
values
(1,'kz11ar1','kzt',1000000),
(1,'us11ar2','usd',2000),
(2,'kz11d3','kzt',500),
(2,'eu11d4','eur',100),
(3,'kz11n5','kzt',150000),
(4,'kz11b6','kzt',10000),
(5,'ru11l7','rub',50000),
(6,'kz11e8','kzt',2500000),
(7,'kz11ai9','kzt',800000),
(8,'us11r10','usd',10000),
(9,'kz11zh11','kzt',30000),
(10,'kz11m12','kzt',200000);

insert into exchange_rates(from_curr,to_curr,rate_value,valid_from,valid_until) 
values
('usd','kzt',470,now()-interval '1 day',null),
('eur','kzt',510,now()-interval '1 day',null),
('rub','kzt',5.5,now()-interval '1 day',null),
('kzt','kzt',1,now()-interval '5 years',null),
('usd','eur',0.92,now()-interval '1 day',null),
('eur','usd',1.09,now()-interval '1 day',null);

insert into ledger(src_acc,dst_acc,amt_raw,curr_raw,applied_rate,amt_kzt,event_kind,event_status,created_at,finished_at,note)
values
(2,1,50000,'kzt',1,50000,'transfer','completed',now()-interval '1h',now()-interval '1h','seed'),
(1,3,100,'usd',470,47000,'transfer','completed',now()-interval '2h',now()-interval '2h','seed'),
(10,12,200,'usd',470,94000,'transfer','completed',now()-interval '3 days',now()-interval '3 days','seed');

insert into audit_events(entity_name,entity_id,event_type,before_state,after_state,actor,ip_addr)
values ('accounts','1','insert',null,to_jsonb(json_build_object('acc',1)),'system','127.0.0.1');

create or replace function fx_rate_async(p_from varchar, p_to varchar)
returns numeric as $$
declare r numeric;
begin
    if p_from = p_to then return 1; end if;

    select rate_value into r
    from exchange_rates
    where from_curr = p_from
      and to_curr = p_to
      and (valid_until is null or valid_until > now())
    order by valid_from desc
    limit 1;
    if r is null then
        return null;
    end if;
    return r;
end;
$$ language plpgsql stable;

create or replace function do_transfer_async(
    p_src_acc text,
    p_dst_acc text,
    p_amt numeric,
    p_curr text,
    p_note text
) returns jsonb as $$
declare
    s_acc accounts%rowtype;
    d_acc accounts%rowtype;
    s_cust customers%rowtype;
    kzt_rate numeric;
    amt_kzt numeric;
    today_total numeric;
    tx_id int;
    debit_in_src numeric;
    rate_src numeric;
    rate_dst numeric;
    credit_dest numeric;
begin
    select * into s_acc from accounts where account_number = p_src_acc for update;
    if not found then
        return jsonb_build_object('ok',false,'err','src_not_found');
    end if;
    select * into d_acc from accounts where account_number = p_dst_acc for update;
    if not found then
        return jsonb_build_object('ok',false,'err','dst_not_found');
    end if;
    if not s_acc.is_active or not d_acc.is_active then
        return jsonb_build_object('ok',false,'err','acc_inactive');
    end if;
    select * into s_cust from customers where customer_id = s_acc.customer_id;
    if s_cust.status <> 'active' then
        return jsonb_build_object('ok',false,'err','cust_locked');
    end if;
    kzt_rate := fx_rate_async(p_curr,'kzt');
    if kzt_rate is null then
        return jsonb_build_object('ok',false,'err','no_rate_kzt');
    end if;
    amt_kzt := round(p_amt * kzt_rate,2);
    select coalesce(sum(amt_kzt),0)
        into today_total
    from ledger
    where src_acc = s_acc.account_id
      and event_status='completed'
      and created_at::date = now()::date;
    if (today_total + amt_kzt) > s_cust.daily_limit_kzt then
        return jsonb_build_object('ok',false,'err','limit_exceeded');
    end if;
    savepoint sp_async;
    if p_curr = s_acc.currency then
        debit_in_src := p_amt;
    else
        rate_src := fx_rate_async(p_curr, s_acc.currency);
        if rate_src is null then
            rollback to sp_async;
            return jsonb_build_object('ok',false,'err','no_src_rate');
        end if;
        debit_in_src := p_amt * rate_src;
    end if;
    if s_acc.balance < debit_in_src then
        rollback to sp_async;
        return jsonb_build_object('ok',false,'err','no_money');
    end if;
    insert into ledger(src_acc,dst_acc,amt_raw,curr_raw,applied_rate,amt_kzt,event_kind,event_status,note)
    values (s_acc.account_id,d_acc.account_id,p_amt,p_curr,kzt_rate,amt_kzt,'transfer','pending',p_note)
    returning trans_id into tx_id;
    update accounts set balance = balance - debit_in_src where account_id = s_acc.account_id;
    if p_curr = d_acc.currency then
        credit_dest := p_amt;
    else
        rate_dst := fx_rate_async(p_curr, d_acc.currency);
        if rate_dst is null then
            rollback to sp_async;
            update ledger set event_status='failed' where trans_id=tx_id;
            return jsonb_build_object('ok',false,'err','no_dst_rate');
        end if;
        credit_dest := p_amt * rate_dst;
    end if;
    update accounts set balance = balance + credit_dest where account_id = d_acc.account_id;
    update ledger
        set event_status='completed', finished_at=now()
        where trans_id = tx_id;
    insert into audit_events(entity_name,entity_id,event_type,after_state,actor)
    values ('ledger',tx_id::text,'insert',(select to_jsonb(l) from ledger l where l.trans_id=tx_id),current_user);
    return jsonb_build_object('ok',true,'tx',tx_id,'kzt',amt_kzt);
exception
    when others then
        rollback to sp_async;
        insert into audit_events(entity_name,event_type,after_state,actor)
        values ('ledger','exception',jsonb_build_object('err',sqlerrm),current_user);
        return jsonb_build_object('ok',false,'err','internal');
end;
$$ language plpgsql;

create or replace view v_customer_asset_overview as
select
    c.customer_id,
    c.full_name,
    c.iin,
    c.email,
    a.account_number,
    a.currency,
    a.balance,
    coalesce((select rate_value from exchange_rates r
              where r.from_curr=a.currency and r.to_curr='kzt'
              order by r.valid_from desc limit 1),1) as r2kzt,
    round(a.balance *
          coalesce((select rate_value from exchange_rates r
                    where r.from_curr=a.currency and r.to_curr='kzt'
                    order by r.valid_from desc limit 1),1),2) as bal_kzt,
    sum(round(a.balance *
          coalesce((select rate_value from exchange_rates rr
                    where rr.from_curr=a.currency and rr.to_curr='kzt'
                    order by rr.valid_from desc limit 1),1),2))
          over(partition by c.customer_id) as total_kzt,
    rank() over(order by sum(round(a.balance *
          coalesce((select rate_value from exchange_rates rr
                    where rr.from_curr=a.currency and rr.to_curr='kzt'
                    order by rr.valid_from desc limit 1),1),2))
          over(partition by c.customer_id) desc)
          as wealth_rank
from customers c
join accounts a on a.customer_id = c.customer_id;
create or replace view v_daily_flow_async as
select
    date_trunc('day',created_at)::date as day,
    event_kind,
    count(*) as cnt,
    sum(amt_kzt) as vol_kzt,
    avg(amt_kzt) as avg_kzt,
    sum(sum(amt_kzt)) over(order by date_trunc('day',created_at)::date) as cumulative_kzt,
    round(
        100 * (sum(amt_kzt) -
        lag(sum(amt_kzt)) over(order by date_trunc('day',created_at)::date))
        / nullif(lag(sum(amt_kzt)) over(order by date_trunc('day',created_at)::date),0),2
    ) as day_diff
from ledger
where event_status='completed'
group by date_trunc('day',created_at)::date, event_kind
order by day;
create or replace view v_flagged_ops
with (security_barrier = true) as
select
    l.trans_id,
    l.src_acc,
    l.dst_acc,
    l.amt_kzt,
    l.created_at,
    (l.amt_kzt > 5000000) as above_limit,
    exists (
        select 1
        from ledger x
        where x.src_acc = l.src_acc
          and x.created_at between l.created_at - interval '1 hour'
                              and l.created_at + interval '1 hour'
        having count(*) > 10
    ) as burst_hour,
    exists (
        select 1 from ledger y
        where y.src_acc=l.src_acc
          and y.created_at > l.created_at - interval '1 min'
          and y.created_at < l.created_at
        limit 1
    ) as rapid_fire
from ledger l
where l.event_status='completed';

create unique index idx_acc_num on accounts(account_number);
create index idx_ledger_src_time on ledger(src_acc, created_at desc);
create index idx_acc_active_only on accounts(account_id) where is_active;
create index idx_cust_email_lc on customers(lower(email));
create index idx_audit_json on audit_events using gin ((coalesce(before_state,'{}'::jsonb)) jsonb_path_ops);
create index idx_iin_hash on customers using hash(iin);
create index idx_accnum_cover on accounts(account_number) include(balance);

create or replace function batch_salary_async(
    p_company_acc text,
    p_payload jsonb
) returns jsonb as $$
declare
    comp accounts%rowtype;
    lock_key bigint;
    total_needed numeric := 0;
    row_item jsonb;
    emp_iin text;
    emp_amt numeric;
    emp_desc text;
    emp_cust customers%rowtype;
    emp_acc accounts%rowtype;
    failed jsonb := '[]'::jsonb;
    ok_count int := 0;
    bad_count int := 0;
    company_delta numeric := 0;
begin
    select * into comp from accounts where account_number=p_company_acc;
    if not found then
        return jsonb_build_object('ok',false,'err','company_acc_missing');
    end if;
    lock_key := comp.account_id;
    perform pg_advisory_lock(lock_key);

    for row_item in select * from jsonb_array_elements(p_payload)
    loop
        total_needed := total_needed + (row_item->>'amount')::numeric;
    end loop;

    if comp.balance < total_needed then
        perform pg_advisory_unlock(lock_key);
        return jsonb_build_object('ok',false,'err','company_insufficient');
    end if;

    create temp table tmp_changes(
        acc text primary key,
        delta numeric
    ) on commit drop;

    for row_item in select * from jsonb_array_elements(p_payload)
    loop
        emp_iin := row_item->>'iin';
        emp_amt := (row_item->>'amount')::numeric;
        emp_desc := row_item->>'description';
        begin
            savepoint sp_emp;

            select * into emp_cust from customers where iin=emp_iin;
            if not found then
                failed := failed || jsonb_build_object('iin',emp_iin,'err','cust_missing');
                bad_count := bad_count + 1;
                rollback to sp_emp;
                continue;
            end if;
            select * into emp_acc
            from accounts
            where customer_id = emp_cust.customer_id
              and is_active=true
            order by (currency='kzt') desc
            limit 1;
            if not found then
                failed := failed || jsonb_build_object('iin',emp_iin,'err','no_active_acc');
                bad_count := bad_count + 1;
                rollback to sp_emp;
                continue;
            end if;

            insert into tmp_changes(acc,delta)
            values(emp_acc.account_number, emp_amt)
            on conflict(acc) do update
               set delta = tmp_changes.delta + excluded.delta;

            insert into tmp_changes(acc,delta)
            values(p_company_acc, -emp_amt)
            on conflict(acc) do update
               set delta = tmp_changes.delta + excluded.delta;

            ok_count := ok_count + 1;
            release savepoint sp_emp;

        exception when others then
            failed := failed || jsonb_build_object('iin',emp_iin,'err',sqlerrm);
            bad_count := bad_count + 1;
            rollback to sp_emp;
        end;
    end loop;

    select coalesce(delta,0) into company_delta
    from tmp_changes where acc=p_company_acc;

    if comp.balance + company_delta < 0 then
        perform pg_advisory_unlock(lock_key);
        return jsonb_build_object('ok',false,'err','company_post_negative');
    end if;

    update accounts a
    set balance = a.balance + c.delta
    from tmp_changes c
    where a.account_number = c.acc;

    insert into ledger(src_acc,dst_acc,amt_raw,curr_raw,applied_rate,amt_kzt,event_kind,event_status,created_at,finished_at,note)
    select
        (select account_id from accounts where account_number=p_company_acc),
        (select account_id from accounts where account_number=c.acc),
        c.delta,
        (select currency from accounts where account_number=c.acc),
        1,
        c.delta,
        'salary',
        'completed',
        now(),now(),'batch salary'
    from tmp_changes c
    where c.acc <> p_company_acc and c.delta > 0;

    perform pg_advisory_unlock(lock_key);

    return jsonb_build_object(
        'ok',true,
        'success_count',ok_count,
        'failed_count',bad_count,
        'failed_list',failed
    );
end;
$$ language plpgsql;

create materialized view if not exists mv_salary_daily as
select
    date_trunc('day',created_at)::date as day,
    count(*) filter (where event_kind='salary') as salary_count,
    sum(amt_kzt) filter (where event_kind='salary') as salary_volume
from ledger
group by date_trunc('day',created_at)::date
order by day;

--test 

select do_transfer_async('kz11ar1','kz11n5',10000,'kzt','demo');
select batch_salary_async('kz11m12', '[{"iin":"880101000001","amount":50000,"description":"jan"}, {"iin":"900202000002","amount":70000,"description":"jan"}]');


