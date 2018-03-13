--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.6
-- Dumped by pg_dump version 9.6.8

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: person; Type: TABLE; Schema: public; Owner: dnvriend
--

CREATE TABLE public.person (
    id integer NOT NULL,
    name character varying(255),
    age integer
);


ALTER TABLE public.person OWNER TO dnvriend;

--
-- Name: person_id_seq; Type: SEQUENCE; Schema: public; Owner: dnvriend
--

CREATE SEQUENCE public.person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.person_id_seq OWNER TO dnvriend;

--
-- Name: person_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dnvriend
--

ALTER SEQUENCE public.person_id_seq OWNED BY public.person.id;


--
-- Name: person id; Type: DEFAULT; Schema: public; Owner: dnvriend
--

ALTER TABLE ONLY public.person ALTER COLUMN id SET DEFAULT nextval('public.person_id_seq'::regclass);


--
-- Data for Name: person; Type: TABLE DATA; Schema: public; Owner: dnvriend
--

COPY public.person (id, name, age) FROM stdin;
1	Dennis	42
2	Tijger	12
3	Elsa	16
\.


--
-- Name: person_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dnvriend
--

SELECT pg_catalog.setval('public.person_id_seq', 3, true);


--
-- Name: person person_pkey; Type: CONSTRAINT; Schema: public; Owner: dnvriend
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: dnvriend
--

REVOKE ALL ON SCHEMA public FROM rdsadmin;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO dnvriend;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

