--
-- PostgreSQL database dump
--

-- Dumped from database version 10.5 (Debian 10.5-1)
-- Dumped by pg_dump version 10.5 (Debian 10.5-1)

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

-- COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accounts_feedback; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts_feedback (
    id integer NOT NULL,
    feedback_type character varying(100) NOT NULL,
    message text NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    feedback_image character varying(100) NOT NULL
);


ALTER TABLE public.accounts_feedback OWNER TO postgres;

--
-- Name: accounts_feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_feedback_id_seq OWNER TO postgres;

--
-- Name: accounts_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_feedback_id_seq OWNED BY public.accounts_feedback.id;


--
-- Name: accounts_invites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts_invites (
    id integer NOT NULL,
    email character varying(254) NOT NULL,
    created timestamp with time zone NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.accounts_invites OWNER TO postgres;

--
-- Name: accounts_invites_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_invites_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_invites_id_seq OWNER TO postgres;

--
-- Name: accounts_invites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_invites_id_seq OWNED BY public.accounts_invites.id;


--
-- Name: accounts_userfeedback; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts_userfeedback (
    feedback_ptr_id integer NOT NULL,
    rating numeric(3,2) NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.accounts_userfeedback OWNER TO postgres;

--
-- Name: accounts_userprofile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts_userprofile (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(30) NOT NULL,
    last_name character varying(30) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL,
    avatar character varying(100) NOT NULL,
    avatar_thumbnail character varying(100) NOT NULL,
    bio character varying(500) NOT NULL,
    sex character varying(2) NOT NULL,
    birthdate date,
    prefered_radius integer NOT NULL,
    country_code character varying(5) NOT NULL,
    phone character varying(12),
    verified_phone character varying(32),
    user_real_location public.geography(Point,4326),
    user_safe_location public.geography(Point,4326),
    enable_push_notifications boolean NOT NULL,
    verified_email character varying(254),
    area character varying(256) NOT NULL
);


ALTER TABLE public.accounts_userprofile OWNER TO postgres;

--
-- Name: accounts_userprofile_blocked; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts_userprofile_blocked (
    id integer NOT NULL,
    from_userprofile_id integer NOT NULL,
    to_userprofile_id integer NOT NULL
);


ALTER TABLE public.accounts_userprofile_blocked OWNER TO postgres;

--
-- Name: accounts_userprofile_blocked_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_userprofile_blocked_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_userprofile_blocked_id_seq OWNER TO postgres;

--
-- Name: accounts_userprofile_blocked_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_userprofile_blocked_id_seq OWNED BY public.accounts_userprofile_blocked.id;


--
-- Name: accounts_userprofile_close_friends; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts_userprofile_close_friends (
    id integer NOT NULL,
    from_userprofile_id integer NOT NULL,
    to_userprofile_id integer NOT NULL
);


ALTER TABLE public.accounts_userprofile_close_friends OWNER TO postgres;

--
-- Name: accounts_userprofile_close_friends_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_userprofile_close_friends_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_userprofile_close_friends_id_seq OWNER TO postgres;

--
-- Name: accounts_userprofile_close_friends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_userprofile_close_friends_id_seq OWNED BY public.accounts_userprofile_close_friends.id;


--
-- Name: accounts_userprofile_follows; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts_userprofile_follows (
    id integer NOT NULL,
    from_userprofile_id integer NOT NULL,
    to_userprofile_id integer NOT NULL
);


ALTER TABLE public.accounts_userprofile_follows OWNER TO postgres;

--
-- Name: accounts_userprofile_follows_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_userprofile_follows_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_userprofile_follows_id_seq OWNER TO postgres;

--
-- Name: accounts_userprofile_follows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_userprofile_follows_id_seq OWNED BY public.accounts_userprofile_follows.id;


--
-- Name: accounts_userprofile_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts_userprofile_groups (
    id integer NOT NULL,
    userprofile_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.accounts_userprofile_groups OWNER TO postgres;

--
-- Name: accounts_userprofile_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_userprofile_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_userprofile_groups_id_seq OWNER TO postgres;

--
-- Name: accounts_userprofile_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_userprofile_groups_id_seq OWNED BY public.accounts_userprofile_groups.id;


--
-- Name: accounts_userprofile_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_userprofile_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_userprofile_id_seq OWNER TO postgres;

--
-- Name: accounts_userprofile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_userprofile_id_seq OWNED BY public.accounts_userprofile.id;


--
-- Name: accounts_userprofile_user_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.accounts_userprofile_user_permissions (
    id integer NOT NULL,
    userprofile_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.accounts_userprofile_user_permissions OWNER TO postgres;

--
-- Name: accounts_userprofile_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_userprofile_user_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_userprofile_user_permissions_id_seq OWNER TO postgres;

--
-- Name: accounts_userprofile_user_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_userprofile_user_permissions_id_seq OWNED BY public.accounts_userprofile_user_permissions.id;


--
-- Name: actstream_action; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.actstream_action (
    id integer NOT NULL,
    actor_object_id character varying(255) NOT NULL,
    verb character varying(255) NOT NULL,
    description text,
    target_object_id character varying(255),
    action_object_object_id character varying(255),
    "timestamp" timestamp with time zone NOT NULL,
    public boolean NOT NULL,
    action_object_content_type_id integer,
    actor_content_type_id integer NOT NULL,
    target_content_type_id integer
);


ALTER TABLE public.actstream_action OWNER TO postgres;

--
-- Name: actstream_action_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.actstream_action_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.actstream_action_id_seq OWNER TO postgres;

--
-- Name: actstream_action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.actstream_action_id_seq OWNED BY public.actstream_action.id;


--
-- Name: actstream_follow; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.actstream_follow (
    id integer NOT NULL,
    object_id character varying(255) NOT NULL,
    actor_only boolean NOT NULL,
    started timestamp with time zone NOT NULL,
    content_type_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.actstream_follow OWNER TO postgres;

--
-- Name: actstream_follow_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.actstream_follow_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.actstream_follow_id_seq OWNER TO postgres;

--
-- Name: actstream_follow_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.actstream_follow_id_seq OWNED BY public.actstream_follow.id;


--
-- Name: appnotifications_device; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appnotifications_device (
    id integer NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    platform character varying(7) NOT NULL,
    token character varying(255),
    user_id integer
);


ALTER TABLE public.appnotifications_device OWNER TO postgres;

--
-- Name: appnotifications_device_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.appnotifications_device_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.appnotifications_device_id_seq OWNER TO postgres;

--
-- Name: appnotifications_device_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.appnotifications_device_id_seq OWNED BY public.appnotifications_device.id;


--
-- Name: auth_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(80) NOT NULL
);


ALTER TABLE public.auth_group OWNER TO postgres;

--
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_group_id_seq OWNER TO postgres;

--
-- Name: auth_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_group_id_seq OWNED BY public.auth_group.id;


--
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_group_permissions (
    id integer NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_group_permissions OWNER TO postgres;

--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_group_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_group_permissions_id_seq OWNER TO postgres;

--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_group_permissions_id_seq OWNED BY public.auth_group_permissions.id;


--
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


ALTER TABLE public.auth_permission OWNER TO postgres;

--
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_permission_id_seq OWNER TO postgres;

--
-- Name: auth_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_permission_id_seq OWNED BY public.auth_permission.id;


--
-- Name: authtoken_token; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.authtoken_token (
    key character varying(40) NOT NULL,
    created timestamp with time zone NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.authtoken_token OWNER TO postgres;

--
-- Name: chat_message; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_message (
    id integer NOT NULL,
    message character varying(255) NOT NULL,
    created timestamp with time zone NOT NULL,
    room_id integer NOT NULL,
    user_id integer NOT NULL,
    location public.geography(Point,4326),
    media_file_keys character varying(36)[] NOT NULL,
    message_type character varying(3) NOT NULL,
    parent_id integer,
    forwarded_message_id integer,
    edited timestamp with time zone,
    is_seen boolean NOT NULL,
    private_post_id integer
);


ALTER TABLE public.chat_message OWNER TO postgres;

--
-- Name: chat_message_hashtags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_message_hashtags (
    id integer NOT NULL,
    message_id integer NOT NULL,
    interest_id integer NOT NULL
);


ALTER TABLE public.chat_message_hashtags OWNER TO postgres;

--
-- Name: chat_message_hashtags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_message_hashtags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_message_hashtags_id_seq OWNER TO postgres;

--
-- Name: chat_message_hashtags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_message_hashtags_id_seq OWNED BY public.chat_message_hashtags.id;


--
-- Name: chat_message_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_message_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_message_id_seq OWNER TO postgres;

--
-- Name: chat_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_message_id_seq OWNED BY public.chat_message.id;


--
-- Name: chat_message_users_seen_message; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_message_users_seen_message (
    id integer NOT NULL,
    message_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.chat_message_users_seen_message OWNER TO postgres;

--
-- Name: chat_message_users_seen_message_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_message_users_seen_message_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_message_users_seen_message_id_seq OWNER TO postgres;

--
-- Name: chat_message_users_seen_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_message_users_seen_message_id_seq OWNED BY public.chat_message_users_seen_message.id;


--
-- Name: chat_message_usertags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_message_usertags (
    id integer NOT NULL,
    message_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.chat_message_usertags OWNER TO postgres;

--
-- Name: chat_message_usertags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_message_usertags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_message_usertags_id_seq OWNER TO postgres;

--
-- Name: chat_message_usertags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_message_usertags_id_seq OWNED BY public.chat_message_usertags.id;


--
-- Name: chat_room; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_room (
    id integer NOT NULL,
    key character varying(36) NOT NULL,
    private boolean NOT NULL,
    location public.geography(Point,4326),
    created timestamp with time zone NOT NULL,
    interest_id integer,
    last_interaction timestamp with time zone NOT NULL,
    title character varying(36) NOT NULL,
    chat_type character varying(36),
    color character varying(7),
    reach_area_radius numeric(13,4),
    place_id integer,
    safe_location public.geography(Point,4326)
);


ALTER TABLE public.chat_room OWNER TO postgres;

--
-- Name: chat_room_administrators; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_room_administrators (
    id integer NOT NULL,
    room_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.chat_room_administrators OWNER TO postgres;

--
-- Name: chat_room_administrators_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_room_administrators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_room_administrators_id_seq OWNER TO postgres;

--
-- Name: chat_room_administrators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_room_administrators_id_seq OWNED BY public.chat_room_administrators.id;


--
-- Name: chat_room_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_room_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_room_id_seq OWNER TO postgres;

--
-- Name: chat_room_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_room_id_seq OWNED BY public.chat_room.id;


--
-- Name: chat_room_interests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_room_interests (
    id integer NOT NULL,
    room_id integer NOT NULL,
    interest_id integer NOT NULL
);


ALTER TABLE public.chat_room_interests OWNER TO postgres;

--
-- Name: chat_room_interests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_room_interests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_room_interests_id_seq OWNER TO postgres;

--
-- Name: chat_room_interests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_room_interests_id_seq OWNED BY public.chat_room_interests.id;


--
-- Name: chat_room_pending; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_room_pending (
    id integer NOT NULL,
    room_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.chat_room_pending OWNER TO postgres;

--
-- Name: chat_room_pending_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_room_pending_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_room_pending_id_seq OWNER TO postgres;

--
-- Name: chat_room_pending_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_room_pending_id_seq OWNED BY public.chat_room_pending.id;


--
-- Name: chat_room_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_room_users (
    id integer NOT NULL,
    room_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.chat_room_users OWNER TO postgres;

--
-- Name: chat_room_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_room_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_room_users_id_seq OWNER TO postgres;

--
-- Name: chat_room_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_room_users_id_seq OWNED BY public.chat_room_users.id;


--
-- Name: comments_comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comments_comments (
    id integer NOT NULL,
    comment character varying(300) NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    "isDisabled" boolean NOT NULL,
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    media_file_keys character varying(36)[] NOT NULL,
    parent_id integer
);


ALTER TABLE public.comments_comments OWNER TO postgres;

--
-- Name: comments_comments_downvotes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comments_comments_downvotes (
    id integer NOT NULL,
    comments_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.comments_comments_downvotes OWNER TO postgres;

--
-- Name: comments_comments_downvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comments_comments_downvotes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comments_comments_downvotes_id_seq OWNER TO postgres;

--
-- Name: comments_comments_downvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comments_comments_downvotes_id_seq OWNED BY public.comments_comments_downvotes.id;


--
-- Name: comments_comments_hashtags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comments_comments_hashtags (
    id integer NOT NULL,
    comments_id integer NOT NULL,
    interest_id integer NOT NULL
);


ALTER TABLE public.comments_comments_hashtags OWNER TO postgres;

--
-- Name: comments_comments_hashtags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comments_comments_hashtags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comments_comments_hashtags_id_seq OWNER TO postgres;

--
-- Name: comments_comments_hashtags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comments_comments_hashtags_id_seq OWNED BY public.comments_comments_hashtags.id;


--
-- Name: comments_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comments_comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comments_comments_id_seq OWNER TO postgres;

--
-- Name: comments_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comments_comments_id_seq OWNED BY public.comments_comments.id;


--
-- Name: comments_comments_upvotes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comments_comments_upvotes (
    id integer NOT NULL,
    comments_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.comments_comments_upvotes OWNER TO postgres;

--
-- Name: comments_comments_upvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comments_comments_upvotes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comments_comments_upvotes_id_seq OWNER TO postgres;

--
-- Name: comments_comments_upvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comments_comments_upvotes_id_seq OWNED BY public.comments_comments_upvotes.id;


--
-- Name: comments_comments_usertags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comments_comments_usertags (
    id integer NOT NULL,
    comments_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.comments_comments_usertags OWNER TO postgres;

--
-- Name: comments_comments_usertags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comments_comments_usertags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comments_comments_usertags_id_seq OWNER TO postgres;

--
-- Name: comments_comments_usertags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comments_comments_usertags_id_seq OWNED BY public.comments_comments_usertags.id;


--
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id integer NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);


ALTER TABLE public.django_admin_log OWNER TO postgres;

--
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_admin_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_admin_log_id_seq OWNER TO postgres;

--
-- Name: django_admin_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_admin_log_id_seq OWNED BY public.django_admin_log.id;


--
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


ALTER TABLE public.django_content_type OWNER TO postgres;

--
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_content_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_content_type_id_seq OWNER TO postgres;

--
-- Name: django_content_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_content_type_id_seq OWNED BY public.django_content_type.id;


--
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_migrations (
    id integer NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


ALTER TABLE public.django_migrations OWNER TO postgres;

--
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_migrations_id_seq OWNER TO postgres;

--
-- Name: django_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_migrations_id_seq OWNED BY public.django_migrations.id;


--
-- Name: django_session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


ALTER TABLE public.django_session OWNER TO postgres;

--
-- Name: django_site; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_site (
    id integer NOT NULL,
    domain character varying(100) NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.django_site OWNER TO postgres;

--
-- Name: django_site_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_site_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_site_id_seq OWNER TO postgres;

--
-- Name: django_site_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_site_id_seq OWNED BY public.django_site.id;


--
-- Name: interests_interest; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.interests_interest (
    id integer NOT NULL,
    name character varying(25) NOT NULL,
    hashtag character varying(25) NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    "isDisabled" boolean NOT NULL
);


ALTER TABLE public.interests_interest OWNER TO postgres;

--
-- Name: interests_interest_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.interests_interest_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.interests_interest_id_seq OWNER TO postgres;

--
-- Name: interests_interest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.interests_interest_id_seq OWNED BY public.interests_interest.id;


--
-- Name: interests_userinterest; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.interests_userinterest (
    id integer NOT NULL,
    rating smallint NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    interest_id integer NOT NULL,
    user_id integer NOT NULL,
    CONSTRAINT interests_userinterest_rating_check CHECK ((rating >= 0))
);


ALTER TABLE public.interests_userinterest OWNER TO postgres;

--
-- Name: interests_userinterest_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.interests_userinterest_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.interests_userinterest_id_seq OWNER TO postgres;

--
-- Name: interests_userinterest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.interests_userinterest_id_seq OWNED BY public.interests_userinterest.id;


--
-- Name: notifications_notification; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications_notification (
    id integer NOT NULL,
    level character varying(20) NOT NULL,
    unread boolean NOT NULL,
    actor_object_id character varying(255) NOT NULL,
    verb character varying(255) NOT NULL,
    description text,
    target_object_id character varying(255),
    action_object_object_id character varying(255),
    "timestamp" timestamp with time zone NOT NULL,
    public boolean NOT NULL,
    action_object_content_type_id integer,
    actor_content_type_id integer NOT NULL,
    recipient_id integer NOT NULL,
    target_content_type_id integer,
    deleted boolean NOT NULL,
    emailed boolean NOT NULL,
    data text
);


ALTER TABLE public.notifications_notification OWNER TO postgres;

--
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_notification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_notification_id_seq OWNER TO postgres;

--
-- Name: notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_notification_id_seq OWNED BY public.notifications_notification.id;


--
-- Name: places_place; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.places_place (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    place_id character varying(256) NOT NULL,
    location public.geography(Point,4326) NOT NULL,
    address text,
    icon character varying(256),
    created timestamp with time zone,
    updated timestamp with time zone NOT NULL,
    vicinity character varying(256) NOT NULL
);


ALTER TABLE public.places_place OWNER TO postgres;

--
-- Name: places_place_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.places_place_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.places_place_id_seq OWNER TO postgres;

--
-- Name: places_place_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.places_place_id_seq OWNED BY public.places_place.id;


--
-- Name: places_place_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.places_place_types (
    id integer NOT NULL,
    place_id integer NOT NULL,
    placetype_id integer NOT NULL
);


ALTER TABLE public.places_place_types OWNER TO postgres;

--
-- Name: places_place_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.places_place_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.places_place_types_id_seq OWNER TO postgres;

--
-- Name: places_place_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.places_place_types_id_seq OWNED BY public.places_place_types.id;


--
-- Name: places_placetype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.places_placetype (
    id integer NOT NULL,
    name character varying(64) NOT NULL
);


ALTER TABLE public.places_placetype OWNER TO postgres;

--
-- Name: places_placetype_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.places_placetype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.places_placetype_id_seq OWNER TO postgres;

--
-- Name: places_placetype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.places_placetype_id_seq OWNED BY public.places_placetype.id;


--
-- Name: pst_event; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pst_event (
    post_ptr_id integer NOT NULL,
    date timestamp with time zone NOT NULL,
    event_location public.geography(Point,4326) NOT NULL
);


ALTER TABLE public.pst_event OWNER TO postgres;

--
-- Name: pst_event_attendees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pst_event_attendees (
    id integer NOT NULL,
    event_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.pst_event_attendees OWNER TO postgres;

--
-- Name: pst_event_attendees_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pst_event_attendees_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pst_event_attendees_id_seq OWNER TO postgres;

--
-- Name: pst_event_attendees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pst_event_attendees_id_seq OWNED BY public.pst_event_attendees.id;


--
-- Name: pst_poll; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pst_poll (
    post_ptr_id integer NOT NULL
);


ALTER TABLE public.pst_poll OWNER TO postgres;

--
-- Name: pst_pollitem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pst_pollitem (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    poll_id integer NOT NULL,
    media_file_keys character varying(36)[] NOT NULL
);


ALTER TABLE public.pst_pollitem OWNER TO postgres;

--
-- Name: pst_pollitem_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pst_pollitem_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pst_pollitem_id_seq OWNER TO postgres;

--
-- Name: pst_pollitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pst_pollitem_id_seq OWNED BY public.pst_pollitem.id;


--
-- Name: pst_pollitem_votes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pst_pollitem_votes (
    id integer NOT NULL,
    pollitem_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.pst_pollitem_votes OWNER TO postgres;

--
-- Name: pst_pollitem_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pst_pollitem_votes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pst_pollitem_votes_id_seq OWNER TO postgres;

--
-- Name: pst_pollitem_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pst_pollitem_votes_id_seq OWNED BY public.pst_pollitem_votes.id;


--
-- Name: pst_post; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pst_post (
    id integer NOT NULL,
    title character varying(64),
    body text NOT NULL,
    location public.geography(Point,4326),
    fake_location public.geography(Point,4326),
    updated timestamp with time zone NOT NULL,
    created timestamp with time zone NOT NULL,
    paid_post boolean NOT NULL,
    paid_post_cost integer NOT NULL,
    private boolean NOT NULL,
    parent_id integer,
    user_id integer NOT NULL,
    place_id integer,
    media_file_keys character varying(36)[] NOT NULL,
    post_type character varying(10) NOT NULL
);


ALTER TABLE public.pst_post OWNER TO postgres;

--
-- Name: pst_post_downvotes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pst_post_downvotes (
    id integer NOT NULL,
    post_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.pst_post_downvotes OWNER TO postgres;

--
-- Name: pst_post_downvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pst_post_downvotes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pst_post_downvotes_id_seq OWNER TO postgres;

--
-- Name: pst_post_downvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pst_post_downvotes_id_seq OWNED BY public.pst_post_downvotes.id;


--
-- Name: pst_post_hashtags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pst_post_hashtags (
    id integer NOT NULL,
    post_id integer NOT NULL,
    interest_id integer NOT NULL
);


ALTER TABLE public.pst_post_hashtags OWNER TO postgres;

--
-- Name: pst_post_hashtags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pst_post_hashtags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pst_post_hashtags_id_seq OWNER TO postgres;

--
-- Name: pst_post_hashtags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pst_post_hashtags_id_seq OWNED BY public.pst_post_hashtags.id;


--
-- Name: pst_post_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pst_post_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pst_post_id_seq OWNER TO postgres;

--
-- Name: pst_post_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pst_post_id_seq OWNED BY public.pst_post.id;


--
-- Name: pst_post_upvotes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pst_post_upvotes (
    id integer NOT NULL,
    post_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.pst_post_upvotes OWNER TO postgres;

--
-- Name: pst_post_upvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pst_post_upvotes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pst_post_upvotes_id_seq OWNER TO postgres;

--
-- Name: pst_post_upvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pst_post_upvotes_id_seq OWNED BY public.pst_post_upvotes.id;


--
-- Name: pst_post_usertags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pst_post_usertags (
    id integer NOT NULL,
    post_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


ALTER TABLE public.pst_post_usertags OWNER TO postgres;

--
-- Name: pst_post_usertags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pst_post_usertags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pst_post_usertags_id_seq OWNER TO postgres;

--
-- Name: pst_post_usertags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pst_post_usertags_id_seq OWNED BY public.pst_post_usertags.id;


--
-- Name: pst_votepost; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pst_votepost (
    post_ptr_id integer NOT NULL
);


ALTER TABLE public.pst_votepost OWNER TO postgres;

--
-- Name: upload_fileupload; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.upload_fileupload (
    id integer NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    owner_id integer NOT NULL,
    media character varying(100),
    media_type character varying(5) NOT NULL,
    media_key character varying(36) NOT NULL,
    media_thumbnail character varying(100)
);


ALTER TABLE public.upload_fileupload OWNER TO postgres;

--
-- Name: upload_fileupload_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.upload_fileupload_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.upload_fileupload_id_seq OWNER TO postgres;

--
-- Name: upload_fileupload_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.upload_fileupload_id_seq OWNED BY public.upload_fileupload.id;


--
-- Name: accounts_feedback id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_feedback ALTER COLUMN id SET DEFAULT nextval('public.accounts_feedback_id_seq'::regclass);


--
-- Name: accounts_invites id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_invites ALTER COLUMN id SET DEFAULT nextval('public.accounts_invites_id_seq'::regclass);


--
-- Name: accounts_userprofile id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_id_seq'::regclass);


--
-- Name: accounts_userprofile_blocked id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_blocked ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_blocked_id_seq'::regclass);


--
-- Name: accounts_userprofile_close_friends id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_close_friends ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_close_friends_id_seq'::regclass);


--
-- Name: accounts_userprofile_follows id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_follows ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_follows_id_seq'::regclass);


--
-- Name: accounts_userprofile_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_groups ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_groups_id_seq'::regclass);


--
-- Name: accounts_userprofile_user_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_user_permissions ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_user_permissions_id_seq'::regclass);


--
-- Name: actstream_action id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actstream_action ALTER COLUMN id SET DEFAULT nextval('public.actstream_action_id_seq'::regclass);


--
-- Name: actstream_follow id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actstream_follow ALTER COLUMN id SET DEFAULT nextval('public.actstream_follow_id_seq'::regclass);


--
-- Name: appnotifications_device id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appnotifications_device ALTER COLUMN id SET DEFAULT nextval('public.appnotifications_device_id_seq'::regclass);


--
-- Name: auth_group id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group ALTER COLUMN id SET DEFAULT nextval('public.auth_group_id_seq'::regclass);


--
-- Name: auth_group_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions ALTER COLUMN id SET DEFAULT nextval('public.auth_group_permissions_id_seq'::regclass);


--
-- Name: auth_permission id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission ALTER COLUMN id SET DEFAULT nextval('public.auth_permission_id_seq'::regclass);


--
-- Name: chat_message id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message ALTER COLUMN id SET DEFAULT nextval('public.chat_message_id_seq'::regclass);


--
-- Name: chat_message_hashtags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_hashtags ALTER COLUMN id SET DEFAULT nextval('public.chat_message_hashtags_id_seq'::regclass);


--
-- Name: chat_message_users_seen_message id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_users_seen_message ALTER COLUMN id SET DEFAULT nextval('public.chat_message_users_seen_message_id_seq'::regclass);


--
-- Name: chat_message_usertags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_usertags ALTER COLUMN id SET DEFAULT nextval('public.chat_message_usertags_id_seq'::regclass);


--
-- Name: chat_room id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room ALTER COLUMN id SET DEFAULT nextval('public.chat_room_id_seq'::regclass);


--
-- Name: chat_room_administrators id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_administrators ALTER COLUMN id SET DEFAULT nextval('public.chat_room_administrators_id_seq'::regclass);


--
-- Name: chat_room_interests id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_interests ALTER COLUMN id SET DEFAULT nextval('public.chat_room_interests_id_seq'::regclass);


--
-- Name: chat_room_pending id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_pending ALTER COLUMN id SET DEFAULT nextval('public.chat_room_pending_id_seq'::regclass);


--
-- Name: chat_room_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_users ALTER COLUMN id SET DEFAULT nextval('public.chat_room_users_id_seq'::regclass);


--
-- Name: comments_comments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments ALTER COLUMN id SET DEFAULT nextval('public.comments_comments_id_seq'::regclass);


--
-- Name: comments_comments_downvotes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_downvotes ALTER COLUMN id SET DEFAULT nextval('public.comments_comments_downvotes_id_seq'::regclass);


--
-- Name: comments_comments_hashtags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_hashtags ALTER COLUMN id SET DEFAULT nextval('public.comments_comments_hashtags_id_seq'::regclass);


--
-- Name: comments_comments_upvotes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_upvotes ALTER COLUMN id SET DEFAULT nextval('public.comments_comments_upvotes_id_seq'::regclass);


--
-- Name: comments_comments_usertags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_usertags ALTER COLUMN id SET DEFAULT nextval('public.comments_comments_usertags_id_seq'::regclass);


--
-- Name: django_admin_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log ALTER COLUMN id SET DEFAULT nextval('public.django_admin_log_id_seq'::regclass);


--
-- Name: django_content_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_content_type ALTER COLUMN id SET DEFAULT nextval('public.django_content_type_id_seq'::regclass);


--
-- Name: django_migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_migrations ALTER COLUMN id SET DEFAULT nextval('public.django_migrations_id_seq'::regclass);


--
-- Name: django_site id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_site ALTER COLUMN id SET DEFAULT nextval('public.django_site_id_seq'::regclass);


--
-- Name: interests_interest id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interests_interest ALTER COLUMN id SET DEFAULT nextval('public.interests_interest_id_seq'::regclass);


--
-- Name: interests_userinterest id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interests_userinterest ALTER COLUMN id SET DEFAULT nextval('public.interests_userinterest_id_seq'::regclass);


--
-- Name: notifications_notification id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications_notification ALTER COLUMN id SET DEFAULT nextval('public.notifications_notification_id_seq'::regclass);


--
-- Name: places_place id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places_place ALTER COLUMN id SET DEFAULT nextval('public.places_place_id_seq'::regclass);


--
-- Name: places_place_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places_place_types ALTER COLUMN id SET DEFAULT nextval('public.places_place_types_id_seq'::regclass);


--
-- Name: places_placetype id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places_placetype ALTER COLUMN id SET DEFAULT nextval('public.places_placetype_id_seq'::regclass);


--
-- Name: pst_event_attendees id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_event_attendees ALTER COLUMN id SET DEFAULT nextval('public.pst_event_attendees_id_seq'::regclass);


--
-- Name: pst_pollitem id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_pollitem ALTER COLUMN id SET DEFAULT nextval('public.pst_pollitem_id_seq'::regclass);


--
-- Name: pst_pollitem_votes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_pollitem_votes ALTER COLUMN id SET DEFAULT nextval('public.pst_pollitem_votes_id_seq'::regclass);


--
-- Name: pst_post id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post ALTER COLUMN id SET DEFAULT nextval('public.pst_post_id_seq'::regclass);


--
-- Name: pst_post_downvotes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_downvotes ALTER COLUMN id SET DEFAULT nextval('public.pst_post_downvotes_id_seq'::regclass);


--
-- Name: pst_post_hashtags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_hashtags ALTER COLUMN id SET DEFAULT nextval('public.pst_post_hashtags_id_seq'::regclass);


--
-- Name: pst_post_upvotes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_upvotes ALTER COLUMN id SET DEFAULT nextval('public.pst_post_upvotes_id_seq'::regclass);


--
-- Name: pst_post_usertags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_usertags ALTER COLUMN id SET DEFAULT nextval('public.pst_post_usertags_id_seq'::regclass);


--
-- Name: upload_fileupload id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.upload_fileupload ALTER COLUMN id SET DEFAULT nextval('public.upload_fileupload_id_seq'::regclass);


--
-- Data for Name: accounts_feedback; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts_feedback (id, feedback_type, message, created, updated, feedback_image) FROM stdin;
\.


--
-- Data for Name: accounts_invites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts_invites (id, email, created, user_id) FROM stdin;
\.


--
-- Data for Name: accounts_userfeedback; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts_userfeedback (feedback_ptr_id, rating, user_id) FROM stdin;
\.


--
-- Data for Name: accounts_userprofile; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts_userprofile (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined, avatar, avatar_thumbnail, bio, sex, birthdate, prefered_radius, country_code, phone, verified_phone, user_real_location, user_safe_location, enable_push_notifications, verified_email, area) FROM stdin;
\.


--
-- Data for Name: accounts_userprofile_blocked; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts_userprofile_blocked (id, from_userprofile_id, to_userprofile_id) FROM stdin;
\.


--
-- Data for Name: accounts_userprofile_close_friends; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts_userprofile_close_friends (id, from_userprofile_id, to_userprofile_id) FROM stdin;
\.


--
-- Data for Name: accounts_userprofile_follows; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts_userprofile_follows (id, from_userprofile_id, to_userprofile_id) FROM stdin;
\.


--
-- Data for Name: accounts_userprofile_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts_userprofile_groups (id, userprofile_id, group_id) FROM stdin;
\.


--
-- Data for Name: accounts_userprofile_user_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts_userprofile_user_permissions (id, userprofile_id, permission_id) FROM stdin;
\.


--
-- Data for Name: actstream_action; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.actstream_action (id, actor_object_id, verb, description, target_object_id, action_object_object_id, "timestamp", public, action_object_content_type_id, actor_content_type_id, target_content_type_id) FROM stdin;
\.


--
-- Data for Name: actstream_follow; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.actstream_follow (id, object_id, actor_only, started, content_type_id, user_id) FROM stdin;
\.


--
-- Data for Name: appnotifications_device; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appnotifications_device (id, created, updated, platform, token, user_id) FROM stdin;
\.


--
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_group (id, name) FROM stdin;
\.


--
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_group_permissions (id, group_id, permission_id) FROM stdin;
\.


--
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_permission (id, name, content_type_id, codename) FROM stdin;
1	Can add permission	1	add_permission
2	Can change permission	1	change_permission
3	Can delete permission	1	delete_permission
4	Can add group	2	add_group
5	Can change group	2	change_group
6	Can delete group	2	delete_group
7	Can add content type	3	add_contenttype
8	Can change content type	3	change_contenttype
9	Can delete content type	3	delete_contenttype
10	Can add session	4	add_session
11	Can change session	4	change_session
12	Can delete session	4	delete_session
13	Can add site	5	add_site
14	Can change site	5	change_site
15	Can delete site	5	delete_site
16	Can add log entry	6	add_logentry
17	Can change log entry	6	change_logentry
18	Can delete log entry	6	delete_logentry
19	Can add Token	7	add_token
20	Can change Token	7	change_token
21	Can delete Token	7	delete_token
22	Can add notification	8	add_notification
23	Can change notification	8	change_notification
24	Can delete notification	8	delete_notification
25	Can add user's profile	9	add_userprofile
26	Can change user's profile	9	change_userprofile
27	Can delete user's profile	9	delete_userprofile
28	Can add invite	10	add_invites
29	Can change invite	10	change_invites
30	Can delete invite	10	delete_invites
31	Can add feedback	11	add_feedback
32	Can change feedback	11	change_feedback
33	Can delete feedback	11	delete_feedback
34	Can add user's feedback	12	add_userfeedback
35	Can change user's feedback	12	change_userfeedback
36	Can delete user's feedback	12	delete_userfeedback
37	Can add post	13	add_post
38	Can change post	13	change_post
39	Can delete post	13	delete_post
40	Can add event post	14	add_event
41	Can change event post	14	change_event
42	Can delete event post	14	delete_event
43	Can add poll post	15	add_poll
44	Can change poll post	15	change_poll
45	Can delete poll post	15	delete_poll
46	Can add poll item	16	add_pollitem
47	Can change poll item	16	change_pollitem
48	Can delete poll item	16	delete_pollitem
49	Can add vote post	17	add_votepost
50	Can change vote post	17	change_votepost
51	Can delete vote post	17	delete_votepost
52	Can add interest	18	add_interest
53	Can change interest	18	change_interest
54	Can delete interest	18	delete_interest
55	Can add user's interest	19	add_userinterest
56	Can change user's interest	19	change_userinterest
57	Can delete user's interest	19	delete_userinterest
58	Can add comment	20	add_comments
59	Can change comment	20	change_comments
60	Can delete comment	20	delete_comments
61	Can add media file	21	add_fileupload
62	Can change media file	21	change_fileupload
63	Can delete media file	21	delete_fileupload
64	Can add place	22	add_place
65	Can change place	22	change_place
66	Can delete place	22	delete_place
67	Can add place type	23	add_placetype
68	Can change place type	23	change_placetype
69	Can delete place type	23	delete_placetype
70	Can add chat message	24	add_message
71	Can change chat message	24	change_message
72	Can delete chat message	24	delete_message
73	Can add chat room	25	add_room
74	Can change chat room	25	change_room
75	Can delete chat room	25	delete_room
76	Can add device	26	add_device
77	Can change device	26	change_device
78	Can delete device	26	delete_device
79	Can add action	27	add_action
80	Can change action	27	change_action
81	Can delete action	27	delete_action
82	Can add follow	28	add_follow
83	Can change follow	28	change_follow
84	Can delete follow	28	delete_follow
\.


--
-- Data for Name: authtoken_token; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.authtoken_token (key, created, user_id) FROM stdin;
\.


--
-- Data for Name: chat_message; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_message (id, message, created, room_id, user_id, location, media_file_keys, message_type, parent_id, forwarded_message_id, edited, is_seen, private_post_id) FROM stdin;
\.


--
-- Data for Name: chat_message_hashtags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_message_hashtags (id, message_id, interest_id) FROM stdin;
\.


--
-- Data for Name: chat_message_users_seen_message; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_message_users_seen_message (id, message_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: chat_message_usertags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_message_usertags (id, message_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: chat_room; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_room (id, key, private, location, created, interest_id, last_interaction, title, chat_type, color, reach_area_radius, place_id, safe_location) FROM stdin;
\.


--
-- Data for Name: chat_room_administrators; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_room_administrators (id, room_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: chat_room_interests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_room_interests (id, room_id, interest_id) FROM stdin;
\.


--
-- Data for Name: chat_room_pending; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_room_pending (id, room_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: chat_room_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_room_users (id, room_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: comments_comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments_comments (id, comment, created, updated, "isDisabled", post_id, user_id, media_file_keys, parent_id) FROM stdin;
\.


--
-- Data for Name: comments_comments_downvotes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments_comments_downvotes (id, comments_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: comments_comments_hashtags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments_comments_hashtags (id, comments_id, interest_id) FROM stdin;
\.


--
-- Data for Name: comments_comments_upvotes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments_comments_upvotes (id, comments_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: comments_comments_usertags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments_comments_usertags (id, comments_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: django_admin_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_admin_log (id, action_time, object_id, object_repr, action_flag, change_message, content_type_id, user_id) FROM stdin;
\.


--
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_content_type (id, app_label, model) FROM stdin;
1	auth	permission
2	auth	group
3	contenttypes	contenttype
4	sessions	session
5	sites	site
6	admin	logentry
7	authtoken	token
8	notifications	notification
9	accounts	userprofile
10	accounts	invites
11	accounts	feedback
12	accounts	userfeedback
13	pst	post
14	pst	event
15	pst	poll
16	pst	pollitem
17	pst	votepost
18	interests	interest
19	interests	userinterest
20	comments	comments
21	upload	fileupload
22	places	place
23	places	placetype
24	chat	message
25	chat	room
26	appnotifications	device
27	actstream	action
28	actstream	follow
\.


--
-- Data for Name: django_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_migrations (id, app, name, applied) FROM stdin;
1	appnotifications	0001_initial	2018-08-29 15:28:01.712794+00
2	appnotifications	0002_auto_20180505_2347	2018-08-29 15:28:01.844692+00
3	appnotifications	0003_auto_20180506_1436	2018-08-29 15:28:01.88955+00
4	appnotifications	0004_auto_20180607_1820	2018-08-29 15:28:01.908118+00
5	contenttypes	0001_initial	2018-08-29 15:28:02.057887+00
6	contenttypes	0002_remove_content_type_name	2018-08-29 15:28:02.100564+00
7	auth	0001_initial	2018-08-29 15:28:02.960927+00
8	auth	0002_alter_permission_name_max_length	2018-08-29 15:28:02.990174+00
9	auth	0003_alter_user_email_max_length	2018-08-29 15:28:03.01763+00
10	auth	0004_alter_user_username_opts	2018-08-29 15:28:03.035691+00
11	auth	0005_alter_user_last_login_null	2018-08-29 15:28:03.062828+00
12	auth	0006_require_contenttypes_0002	2018-08-29 15:28:03.068461+00
13	auth	0007_alter_validators_add_error_messages	2018-08-29 15:28:03.094814+00
14	auth	0008_alter_user_username_max_length	2018-08-29 15:28:03.11402+00
15	accounts	0001_initial	2018-08-29 15:28:04.320753+00
16	accounts	0002_invites	2018-08-29 15:28:04.464181+00
17	accounts	0003_auto_20180505_2308	2018-08-29 15:28:05.035901+00
18	accounts	0004_auto_20180505_2347	2018-08-29 15:28:05.14268+00
19	accounts	0005_auto_20180506_1430	2018-08-29 15:28:05.185643+00
20	accounts	0006_auto_20180506_1436	2018-08-29 15:28:05.241727+00
21	accounts	0007_auto_20180509_2048	2018-08-29 15:28:05.308706+00
22	accounts	0008_auto_20180522_1546	2018-08-29 15:28:05.431952+00
23	accounts	0009_userprofile_area	2018-08-29 15:28:05.779291+00
24	accounts	0010_auto_20180604_0635	2018-08-29 15:28:06.077564+00
25	accounts	0011_auto_20180604_0834	2018-08-29 15:28:06.099802+00
26	accounts	0012_feedback_feedback_image	2018-08-29 15:28:06.254487+00
27	accounts	0013_auto_20180607_1820	2018-08-29 15:28:06.544725+00
28	accounts	0014_auto_20180608_0957	2018-08-29 15:28:07.17976+00
29	accounts	0015_auto_20180608_1127	2018-08-29 15:28:07.471231+00
30	accounts	0016_auto_20180712_2206	2018-08-29 15:28:07.510433+00
31	actstream	0001_initial	2018-08-29 15:28:08.883401+00
32	actstream	0002_remove_action_data	2018-08-29 15:28:08.948988+00
33	admin	0001_initial	2018-08-29 15:28:09.161706+00
34	admin	0002_logentry_remove_auto_add	2018-08-29 15:28:09.215995+00
35	appnotifications	0005_auto_20180608_0957	2018-08-29 15:28:09.495704+00
36	appnotifications	0006_auto_20180608_1127	2018-08-29 15:28:09.560854+00
37	appnotifications	0007_auto_20180620_0840	2018-08-29 15:28:09.706861+00
38	appnotifications	0008_auto_20180620_0854	2018-08-29 15:28:09.750169+00
39	authtoken	0001_initial	2018-08-29 15:28:09.952087+00
40	authtoken	0002_auto_20160226_1747	2018-08-29 15:28:10.21889+00
41	upload	0001_initial	2018-08-29 15:28:10.374762+00
42	upload	0002_auto_20171016_0049	2018-08-29 15:28:10.575479+00
43	interests	0001_initial	2018-08-29 15:28:10.755156+00
44	pst	0001_initial	2018-08-29 15:28:11.77149+00
45	pst	0002_event_poll_pollitem	2018-08-29 15:28:12.371717+00
46	places	0001_initial	2018-08-29 15:28:12.928203+00
47	pst	0003_auto_20170926_0835	2018-08-29 15:28:13.161298+00
48	pst	0004_remove_post_fake_place	2018-08-29 15:28:13.248651+00
49	pst	0005_auto_20171006_0225	2018-08-29 15:28:13.359863+00
50	pst	0006_post_media_type	2018-08-29 15:28:13.426468+00
51	pst	0007_auto_20171016_0302	2018-08-29 15:28:13.88372+00
52	pst	0008_remove_post_media	2018-08-29 15:28:13.972032+00
53	pst	0009_post_media_file_keys	2018-08-29 15:28:14.263839+00
54	pst	0010_votepost	2018-08-29 15:28:14.428673+00
55	pst	0011_post_post_type	2018-08-29 15:28:14.75329+00
56	pst	0012_auto_20180505_2308	2018-08-29 15:28:15.478606+00
57	pst	0013_auto_20180505_2347	2018-08-29 15:28:15.674358+00
58	pst	0014_auto_20180506_1135	2018-08-29 15:28:15.785787+00
59	pst	0015_auto_20180506_1342	2018-08-29 15:28:15.940231+00
60	pst	0016_auto_20180506_1455	2018-08-29 15:28:16.051709+00
61	pst	0017_auto_20180509_2048	2018-08-29 15:28:16.332178+00
62	pst	0018_event_attendees	2018-08-29 15:28:16.598132+00
63	pst	0019_auto_20180523_0930	2018-08-29 15:28:16.662887+00
64	pst	0020_auto_20180608_0957	2018-08-29 15:28:17.042442+00
65	pst	0021_auto_20180608_1127	2018-08-29 15:28:18.364587+00
66	places	0002_auto_20171006_1701	2018-08-29 15:28:18.409612+00
67	places	0003_auto_20180505_2308	2018-08-29 15:28:18.611816+00
68	places	0004_auto_20180506_1455	2018-08-29 15:28:19.19143+00
69	interests	0002_auto_20170925_1820	2018-08-29 15:28:19.477154+00
70	interests	0003_auto_20180505_2347	2018-08-29 15:28:19.777346+00
71	chat	0001_initial	2018-08-29 15:28:20.769706+00
72	chat	0002_message_location	2018-08-29 15:28:20.892839+00
73	chat	0003_auto_20171005_1748	2018-08-29 15:28:20.953604+00
74	chat	0004_room_last_interaction	2018-08-29 15:28:21.270601+00
75	chat	0005_room_title	2018-08-29 15:28:21.572915+00
76	chat	0006_message_media_file_keys	2018-08-29 15:28:21.793475+00
77	chat	0007_message_message_type	2018-08-29 15:28:22.059463+00
78	chat	0008_auto_20171115_2111	2018-08-29 15:28:22.121492+00
79	chat	0009_auto_20180304_0119	2018-08-29 15:28:22.183653+00
80	chat	0010_message_parent	2018-08-29 15:28:22.30547+00
81	chat	0011_room_chat_type	2018-08-29 15:28:22.369594+00
82	chat	0012_message_forwarded_message	2018-08-29 15:28:22.504717+00
83	chat	0013_auto_20180417_1146	2018-08-29 15:28:22.972854+00
84	chat	0014_room_administrators	2018-08-29 15:28:23.326504+00
85	chat	0015_room_pending	2018-08-29 15:28:23.607601+00
86	chat	0016_auto_20180418_1608	2018-08-29 15:28:23.705311+00
87	chat	0017_auto_20180504_1034	2018-08-29 15:28:23.784491+00
88	chat	0018_auto_20180505_2308	2018-08-29 15:28:24.477767+00
89	chat	0019_auto_20180505_2347	2018-08-29 15:28:24.807842+00
90	chat	0020_auto_20180506_1342	2018-08-29 15:28:25.340686+00
91	chat	0021_auto_20180506_1436	2018-08-29 15:28:25.798679+00
92	chat	0022_room_color	2018-08-29 15:28:25.873885+00
93	chat	0023_auto_20180509_2048	2018-08-29 15:28:26.166553+00
94	chat	0024_room_radius	2018-08-29 15:28:26.239891+00
95	chat	0025_room_location_name	2018-08-29 15:28:26.611827+00
96	chat	0026_auto_20180516_1049	2018-08-29 15:28:26.852739+00
97	chat	0027_auto_20180517_0919	2018-08-29 15:28:26.963351+00
98	chat	0028_auto_20180608_0957	2018-08-29 15:28:28.341659+00
99	chat	0029_auto_20180608_1127	2018-08-29 15:28:29.687893+00
100	chat	0030_auto_20180620_0848	2018-08-29 15:28:30.112578+00
101	chat	0031_message_private_post	2018-08-29 15:28:30.243625+00
102	comments	0001_initial	2018-08-29 15:28:31.011523+00
103	comments	0002_comments_media_file_keys	2018-08-29 15:28:31.445088+00
104	comments	0003_comments_parent	2018-08-29 15:28:31.611556+00
105	comments	0004_auto_20180504_1034	2018-08-29 15:28:31.711269+00
106	comments	0005_auto_20180505_2347	2018-08-29 15:28:31.955918+00
107	comments	0006_auto_20180506_1342	2018-08-29 15:28:32.649119+00
108	comments	0007_auto_20180506_1455	2018-08-29 15:28:32.801249+00
109	comments	0008_auto_20180608_0957	2018-08-29 15:28:33.312754+00
110	comments	0009_auto_20180608_1127	2018-08-29 15:28:34.124611+00
111	interests	0004_auto_20180506_1455	2018-08-29 15:28:34.495901+00
112	interests	0005_auto_20180509_2207	2018-08-29 15:28:34.653506+00
113	interests	0006_auto_20180607_2133	2018-08-29 15:28:35.069568+00
114	interests	0007_auto_20180608_0957	2018-08-29 15:28:35.61397+00
115	interests	0008_auto_20180608_1127	2018-08-29 15:28:35.90349+00
116	interests	0009_auto_20180711_1952	2018-08-29 15:28:35.957112+00
117	notifications	0001_initial	2018-08-29 15:28:36.425285+00
118	notifications	0002_auto_20150224_1134	2018-08-29 15:28:37.116199+00
119	notifications	0003_notification_data	2018-08-29 15:28:37.204092+00
120	notifications	0004_auto_20150826_1508	2018-08-29 15:28:37.292338+00
121	notifications	0005_auto_20160504_1520	2018-08-29 15:28:37.371097+00
122	places	0005_place_vicinity	2018-08-29 15:28:37.643351+00
123	places	0006_auto_20180608_0957	2018-08-29 15:28:37.784086+00
124	places	0007_auto_20180608_1127	2018-08-29 15:28:37.840451+00
125	pst	0022_auto_20180711_1952	2018-08-29 15:28:37.940302+00
126	pst	0023_auto_20180726_1233	2018-08-29 15:28:38.028223+00
127	pst	0024_auto_20180829_1419	2018-08-29 15:28:38.45434+00
128	sessions	0001_initial	2018-08-29 15:28:38.651535+00
129	sites	0001_initial	2018-08-29 15:28:38.730755+00
130	sites	0002_alter_domain_unique	2018-08-29 15:28:38.853224+00
131	upload	0003_fileupload_media_key	2018-08-29 15:28:39.087893+00
132	upload	0004_auto_20180505_2347	2018-08-29 15:28:39.320163+00
133	upload	0005_auto_20180506_1455	2018-08-29 15:28:39.474523+00
134	upload	0006_fileupload_media_thumbnail	2018-08-29 15:28:39.563001+00
135	upload	0007_auto_20180608_1127	2018-08-29 15:28:40.260168+00
\.


--
-- Data for Name: django_session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_session (session_key, session_data, expire_date) FROM stdin;
\.


--
-- Data for Name: django_site; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_site (id, domain, name) FROM stdin;
1	example.com	example.com
\.


--
-- Data for Name: interests_interest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.interests_interest (id, name, hashtag, created, updated, "isDisabled") FROM stdin;
\.


--
-- Data for Name: interests_userinterest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.interests_userinterest (id, rating, created, updated, interest_id, user_id) FROM stdin;
\.


--
-- Data for Name: notifications_notification; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications_notification (id, level, unread, actor_object_id, verb, description, target_object_id, action_object_object_id, "timestamp", public, action_object_content_type_id, actor_content_type_id, recipient_id, target_content_type_id, deleted, emailed, data) FROM stdin;
\.


--
-- Data for Name: places_place; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.places_place (id, name, place_id, location, address, icon, created, updated, vicinity) FROM stdin;
\.


--
-- Data for Name: places_place_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.places_place_types (id, place_id, placetype_id) FROM stdin;
\.


--
-- Data for Name: places_placetype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.places_placetype (id, name) FROM stdin;
\.


--
-- Data for Name: pst_event; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pst_event (post_ptr_id, date, event_location) FROM stdin;
\.


--
-- Data for Name: pst_event_attendees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pst_event_attendees (id, event_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: pst_poll; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pst_poll (post_ptr_id) FROM stdin;
\.


--
-- Data for Name: pst_pollitem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pst_pollitem (id, title, poll_id, media_file_keys) FROM stdin;
\.


--
-- Data for Name: pst_pollitem_votes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pst_pollitem_votes (id, pollitem_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: pst_post; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pst_post (id, title, body, location, fake_location, updated, created, paid_post, paid_post_cost, private, parent_id, user_id, place_id, media_file_keys, post_type) FROM stdin;
\.


--
-- Data for Name: pst_post_downvotes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pst_post_downvotes (id, post_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: pst_post_hashtags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pst_post_hashtags (id, post_id, interest_id) FROM stdin;
\.


--
-- Data for Name: pst_post_upvotes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pst_post_upvotes (id, post_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: pst_post_usertags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pst_post_usertags (id, post_id, userprofile_id) FROM stdin;
\.


--
-- Data for Name: pst_votepost; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pst_votepost (post_ptr_id) FROM stdin;
\.


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: upload_fileupload; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.upload_fileupload (id, created, updated, owner_id, media, media_type, media_key, media_thumbnail) FROM stdin;
\.


--
-- Name: accounts_feedback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.accounts_feedback_id_seq', 1, false);


--
-- Name: accounts_invites_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.accounts_invites_id_seq', 1, false);


--
-- Name: accounts_userprofile_blocked_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.accounts_userprofile_blocked_id_seq', 1, false);


--
-- Name: accounts_userprofile_close_friends_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.accounts_userprofile_close_friends_id_seq', 1, false);


--
-- Name: accounts_userprofile_follows_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.accounts_userprofile_follows_id_seq', 1, false);


--
-- Name: accounts_userprofile_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.accounts_userprofile_groups_id_seq', 1, false);


--
-- Name: accounts_userprofile_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.accounts_userprofile_id_seq', 1, false);


--
-- Name: accounts_userprofile_user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.accounts_userprofile_user_permissions_id_seq', 1, false);


--
-- Name: actstream_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.actstream_action_id_seq', 1, false);


--
-- Name: actstream_follow_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.actstream_follow_id_seq', 1, false);


--
-- Name: appnotifications_device_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.appnotifications_device_id_seq', 1, false);


--
-- Name: auth_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_group_id_seq', 1, false);


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_group_permissions_id_seq', 1, false);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_permission_id_seq', 84, true);


--
-- Name: chat_message_hashtags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_message_hashtags_id_seq', 1, false);


--
-- Name: chat_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_message_id_seq', 1, false);


--
-- Name: chat_message_users_seen_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_message_users_seen_message_id_seq', 1, false);


--
-- Name: chat_message_usertags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_message_usertags_id_seq', 1, false);


--
-- Name: chat_room_administrators_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_room_administrators_id_seq', 1, false);


--
-- Name: chat_room_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_room_id_seq', 1, false);


--
-- Name: chat_room_interests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_room_interests_id_seq', 1, false);


--
-- Name: chat_room_pending_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_room_pending_id_seq', 1, false);


--
-- Name: chat_room_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_room_users_id_seq', 1, false);


--
-- Name: comments_comments_downvotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comments_comments_downvotes_id_seq', 1, false);


--
-- Name: comments_comments_hashtags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comments_comments_hashtags_id_seq', 1, false);


--
-- Name: comments_comments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comments_comments_id_seq', 1, false);


--
-- Name: comments_comments_upvotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comments_comments_upvotes_id_seq', 1, false);


--
-- Name: comments_comments_usertags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comments_comments_usertags_id_seq', 1, false);


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_admin_log_id_seq', 1, false);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_content_type_id_seq', 28, true);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_migrations_id_seq', 135, true);


--
-- Name: django_site_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_site_id_seq', 1, true);


--
-- Name: interests_interest_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.interests_interest_id_seq', 1, false);


--
-- Name: interests_userinterest_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.interests_userinterest_id_seq', 1, false);


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_notification_id_seq', 1, false);


--
-- Name: places_place_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.places_place_id_seq', 1, false);


--
-- Name: places_place_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.places_place_types_id_seq', 1, false);


--
-- Name: places_placetype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.places_placetype_id_seq', 1, false);


--
-- Name: pst_event_attendees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pst_event_attendees_id_seq', 1, false);


--
-- Name: pst_pollitem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pst_pollitem_id_seq', 1, false);


--
-- Name: pst_pollitem_votes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pst_pollitem_votes_id_seq', 1, false);


--
-- Name: pst_post_downvotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pst_post_downvotes_id_seq', 1, false);


--
-- Name: pst_post_hashtags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pst_post_hashtags_id_seq', 1, false);


--
-- Name: pst_post_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pst_post_id_seq', 1, false);


--
-- Name: pst_post_upvotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pst_post_upvotes_id_seq', 1, false);


--
-- Name: pst_post_usertags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pst_post_usertags_id_seq', 1, false);


--
-- Name: upload_fileupload_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.upload_fileupload_id_seq', 1, false);


--
-- Name: accounts_feedback accounts_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_feedback
    ADD CONSTRAINT accounts_feedback_pkey PRIMARY KEY (id);


--
-- Name: accounts_invites accounts_invites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_invites
    ADD CONSTRAINT accounts_invites_pkey PRIMARY KEY (id);


--
-- Name: accounts_userfeedback accounts_userfeedback_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userfeedback
    ADD CONSTRAINT accounts_userfeedback_pkey PRIMARY KEY (feedback_ptr_id);


--
-- Name: accounts_userprofile_blocked accounts_userprofile_blo_from_userprofile_id_to_u_2f6bb747_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_blocked
    ADD CONSTRAINT accounts_userprofile_blo_from_userprofile_id_to_u_2f6bb747_uniq UNIQUE (from_userprofile_id, to_userprofile_id);


--
-- Name: accounts_userprofile_blocked accounts_userprofile_blocked_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_blocked
    ADD CONSTRAINT accounts_userprofile_blocked_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile_close_friends accounts_userprofile_clo_from_userprofile_id_to_u_a9366b0c_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_close_friends
    ADD CONSTRAINT accounts_userprofile_clo_from_userprofile_id_to_u_a9366b0c_uniq UNIQUE (from_userprofile_id, to_userprofile_id);


--
-- Name: accounts_userprofile_close_friends accounts_userprofile_close_friends_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_close_friends
    ADD CONSTRAINT accounts_userprofile_close_friends_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile_follows accounts_userprofile_fol_from_userprofile_id_to_u_96a4afdf_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_follows
    ADD CONSTRAINT accounts_userprofile_fol_from_userprofile_id_to_u_96a4afdf_uniq UNIQUE (from_userprofile_id, to_userprofile_id);


--
-- Name: accounts_userprofile_follows accounts_userprofile_follows_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_follows
    ADD CONSTRAINT accounts_userprofile_follows_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile_groups accounts_userprofile_gro_userprofile_id_group_id_36cd9fa6_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_groups
    ADD CONSTRAINT accounts_userprofile_gro_userprofile_id_group_id_36cd9fa6_uniq UNIQUE (userprofile_id, group_id);


--
-- Name: accounts_userprofile_groups accounts_userprofile_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_groups
    ADD CONSTRAINT accounts_userprofile_groups_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile accounts_userprofile_phone_8e09b259_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile
    ADD CONSTRAINT accounts_userprofile_phone_8e09b259_uniq UNIQUE (phone);


--
-- Name: accounts_userprofile accounts_userprofile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile
    ADD CONSTRAINT accounts_userprofile_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile_user_permissions accounts_userprofile_use_userprofile_id_permissio_22053107_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_user_permissions
    ADD CONSTRAINT accounts_userprofile_use_userprofile_id_permissio_22053107_uniq UNIQUE (userprofile_id, permission_id);


--
-- Name: accounts_userprofile_user_permissions accounts_userprofile_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_user_permissions
    ADD CONSTRAINT accounts_userprofile_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile accounts_userprofile_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile
    ADD CONSTRAINT accounts_userprofile_username_key UNIQUE (username);


--
-- Name: actstream_action actstream_action_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actstream_action
    ADD CONSTRAINT actstream_action_pkey PRIMARY KEY (id);


--
-- Name: actstream_follow actstream_follow_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actstream_follow
    ADD CONSTRAINT actstream_follow_pkey PRIMARY KEY (id);


--
-- Name: actstream_follow actstream_follow_user_id_content_type_id__63ca7c27_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actstream_follow
    ADD CONSTRAINT actstream_follow_user_id_content_type_id__63ca7c27_uniq UNIQUE (user_id, content_type_id, object_id);


--
-- Name: appnotifications_device appnotifications_device_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appnotifications_device
    ADD CONSTRAINT appnotifications_device_pkey PRIMARY KEY (id);


--
-- Name: appnotifications_device appnotifications_device_token_6765efeb_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appnotifications_device
    ADD CONSTRAINT appnotifications_device_token_6765efeb_uniq UNIQUE (token);


--
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- Name: authtoken_token authtoken_token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_pkey PRIMARY KEY (key);


--
-- Name: authtoken_token authtoken_token_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_user_id_key UNIQUE (user_id);


--
-- Name: chat_message_hashtags chat_message_hashtags_message_id_interest_id_4a0b0eaa_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_hashtags
    ADD CONSTRAINT chat_message_hashtags_message_id_interest_id_4a0b0eaa_uniq UNIQUE (message_id, interest_id);


--
-- Name: chat_message_hashtags chat_message_hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_hashtags
    ADD CONSTRAINT chat_message_hashtags_pkey PRIMARY KEY (id);


--
-- Name: chat_message chat_message_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_pkey PRIMARY KEY (id);


--
-- Name: chat_message_users_seen_message chat_message_users_seen__message_id_userprofile_i_a58b508b_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_users_seen_message
    ADD CONSTRAINT chat_message_users_seen__message_id_userprofile_i_a58b508b_uniq UNIQUE (message_id, userprofile_id);


--
-- Name: chat_message_users_seen_message chat_message_users_seen_message_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_users_seen_message
    ADD CONSTRAINT chat_message_users_seen_message_pkey PRIMARY KEY (id);


--
-- Name: chat_message_usertags chat_message_usertags_message_id_userprofile_id_a51508ab_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_usertags
    ADD CONSTRAINT chat_message_usertags_message_id_userprofile_id_a51508ab_uniq UNIQUE (message_id, userprofile_id);


--
-- Name: chat_message_usertags chat_message_usertags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_usertags
    ADD CONSTRAINT chat_message_usertags_pkey PRIMARY KEY (id);


--
-- Name: chat_room_administrators chat_room_administrators_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_administrators
    ADD CONSTRAINT chat_room_administrators_pkey PRIMARY KEY (id);


--
-- Name: chat_room_administrators chat_room_administrators_room_id_userprofile_id_5be12aef_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_administrators
    ADD CONSTRAINT chat_room_administrators_room_id_userprofile_id_5be12aef_uniq UNIQUE (room_id, userprofile_id);


--
-- Name: chat_room chat_room_interest_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room
    ADD CONSTRAINT chat_room_interest_id_key UNIQUE (interest_id);


--
-- Name: chat_room_interests chat_room_interests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_interests
    ADD CONSTRAINT chat_room_interests_pkey PRIMARY KEY (id);


--
-- Name: chat_room_interests chat_room_interests_room_id_interest_id_e3ed4a69_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_interests
    ADD CONSTRAINT chat_room_interests_room_id_interest_id_e3ed4a69_uniq UNIQUE (room_id, interest_id);


--
-- Name: chat_room chat_room_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room
    ADD CONSTRAINT chat_room_key_key UNIQUE (key);


--
-- Name: chat_room_pending chat_room_pending_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_pending
    ADD CONSTRAINT chat_room_pending_pkey PRIMARY KEY (id);


--
-- Name: chat_room_pending chat_room_pending_room_id_userprofile_id_165fd6e7_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_pending
    ADD CONSTRAINT chat_room_pending_room_id_userprofile_id_165fd6e7_uniq UNIQUE (room_id, userprofile_id);


--
-- Name: chat_room chat_room_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room
    ADD CONSTRAINT chat_room_pkey PRIMARY KEY (id);


--
-- Name: chat_room_users chat_room_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_users
    ADD CONSTRAINT chat_room_users_pkey PRIMARY KEY (id);


--
-- Name: chat_room_users chat_room_users_room_id_userprofile_id_d31d7c2f_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_users
    ADD CONSTRAINT chat_room_users_room_id_userprofile_id_d31d7c2f_uniq UNIQUE (room_id, userprofile_id);


--
-- Name: comments_comments_downvotes comments_comments_downvo_comments_id_userprofile__7ac29cd9_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_downvotes
    ADD CONSTRAINT comments_comments_downvo_comments_id_userprofile__7ac29cd9_uniq UNIQUE (comments_id, userprofile_id);


--
-- Name: comments_comments_downvotes comments_comments_downvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_downvotes
    ADD CONSTRAINT comments_comments_downvotes_pkey PRIMARY KEY (id);


--
-- Name: comments_comments_hashtags comments_comments_hashta_comments_id_interest_id_dd18f3c9_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_hashtags
    ADD CONSTRAINT comments_comments_hashta_comments_id_interest_id_dd18f3c9_uniq UNIQUE (comments_id, interest_id);


--
-- Name: comments_comments_hashtags comments_comments_hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_hashtags
    ADD CONSTRAINT comments_comments_hashtags_pkey PRIMARY KEY (id);


--
-- Name: comments_comments comments_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments
    ADD CONSTRAINT comments_comments_pkey PRIMARY KEY (id);


--
-- Name: comments_comments_upvotes comments_comments_upvote_comments_id_userprofile__08971208_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_upvotes
    ADD CONSTRAINT comments_comments_upvote_comments_id_userprofile__08971208_uniq UNIQUE (comments_id, userprofile_id);


--
-- Name: comments_comments_upvotes comments_comments_upvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_upvotes
    ADD CONSTRAINT comments_comments_upvotes_pkey PRIMARY KEY (id);


--
-- Name: comments_comments_usertags comments_comments_userta_comments_id_userprofile__4181ee21_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_usertags
    ADD CONSTRAINT comments_comments_userta_comments_id_userprofile__4181ee21_uniq UNIQUE (comments_id, userprofile_id);


--
-- Name: comments_comments_usertags comments_comments_usertags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_usertags
    ADD CONSTRAINT comments_comments_usertags_pkey PRIMARY KEY (id);


--
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- Name: django_site django_site_domain_a2e37b91_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_site
    ADD CONSTRAINT django_site_domain_a2e37b91_uniq UNIQUE (domain);


--
-- Name: django_site django_site_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_site
    ADD CONSTRAINT django_site_pkey PRIMARY KEY (id);


--
-- Name: interests_interest interests_interest_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interests_interest
    ADD CONSTRAINT interests_interest_name_key UNIQUE (name);


--
-- Name: interests_interest interests_interest_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interests_interest
    ADD CONSTRAINT interests_interest_pkey PRIMARY KEY (id);


--
-- Name: interests_userinterest interests_userinterest_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interests_userinterest
    ADD CONSTRAINT interests_userinterest_pkey PRIMARY KEY (id);


--
-- Name: interests_userinterest interests_userinterest_user_id_interest_id_744ff408_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interests_userinterest
    ADD CONSTRAINT interests_userinterest_user_id_interest_id_744ff408_uniq UNIQUE (user_id, interest_id);


--
-- Name: notifications_notification notifications_notification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notification_pkey PRIMARY KEY (id);


--
-- Name: places_place places_place_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places_place
    ADD CONSTRAINT places_place_pkey PRIMARY KEY (id);


--
-- Name: places_place places_place_place_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places_place
    ADD CONSTRAINT places_place_place_id_key UNIQUE (place_id);


--
-- Name: places_place_types places_place_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places_place_types
    ADD CONSTRAINT places_place_types_pkey PRIMARY KEY (id);


--
-- Name: places_place_types places_place_types_place_id_placetype_id_9a9b51ff_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places_place_types
    ADD CONSTRAINT places_place_types_place_id_placetype_id_9a9b51ff_uniq UNIQUE (place_id, placetype_id);


--
-- Name: places_placetype places_placetype_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places_placetype
    ADD CONSTRAINT places_placetype_name_key UNIQUE (name);


--
-- Name: places_placetype places_placetype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places_placetype
    ADD CONSTRAINT places_placetype_pkey PRIMARY KEY (id);


--
-- Name: pst_event_attendees pst_event_attendees_event_id_userprofile_id_175ca335_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_event_attendees
    ADD CONSTRAINT pst_event_attendees_event_id_userprofile_id_175ca335_uniq UNIQUE (event_id, userprofile_id);


--
-- Name: pst_event_attendees pst_event_attendees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_event_attendees
    ADD CONSTRAINT pst_event_attendees_pkey PRIMARY KEY (id);


--
-- Name: pst_event pst_event_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_event
    ADD CONSTRAINT pst_event_pkey PRIMARY KEY (post_ptr_id);


--
-- Name: pst_poll pst_poll_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_poll
    ADD CONSTRAINT pst_poll_pkey PRIMARY KEY (post_ptr_id);


--
-- Name: pst_pollitem pst_pollitem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_pollitem
    ADD CONSTRAINT pst_pollitem_pkey PRIMARY KEY (id);


--
-- Name: pst_pollitem_votes pst_pollitem_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_pollitem_votes
    ADD CONSTRAINT pst_pollitem_votes_pkey PRIMARY KEY (id);


--
-- Name: pst_pollitem_votes pst_pollitem_votes_pollitem_id_userprofile_id_ee2a092e_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_pollitem_votes
    ADD CONSTRAINT pst_pollitem_votes_pollitem_id_userprofile_id_ee2a092e_uniq UNIQUE (pollitem_id, userprofile_id);


--
-- Name: pst_post_downvotes pst_post_downvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_downvotes
    ADD CONSTRAINT pst_post_downvotes_pkey PRIMARY KEY (id);


--
-- Name: pst_post_downvotes pst_post_downvotes_post_id_userprofile_id_23396829_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_downvotes
    ADD CONSTRAINT pst_post_downvotes_post_id_userprofile_id_23396829_uniq UNIQUE (post_id, userprofile_id);


--
-- Name: pst_post_hashtags pst_post_hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_hashtags
    ADD CONSTRAINT pst_post_hashtags_pkey PRIMARY KEY (id);


--
-- Name: pst_post_hashtags pst_post_hashtags_post_id_interest_id_27f024ef_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_hashtags
    ADD CONSTRAINT pst_post_hashtags_post_id_interest_id_27f024ef_uniq UNIQUE (post_id, interest_id);


--
-- Name: pst_post pst_post_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post
    ADD CONSTRAINT pst_post_pkey PRIMARY KEY (id);


--
-- Name: pst_post_upvotes pst_post_upvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_upvotes
    ADD CONSTRAINT pst_post_upvotes_pkey PRIMARY KEY (id);


--
-- Name: pst_post_upvotes pst_post_upvotes_post_id_userprofile_id_93b46ae9_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_upvotes
    ADD CONSTRAINT pst_post_upvotes_post_id_userprofile_id_93b46ae9_uniq UNIQUE (post_id, userprofile_id);


--
-- Name: pst_post_usertags pst_post_usertags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_usertags
    ADD CONSTRAINT pst_post_usertags_pkey PRIMARY KEY (id);


--
-- Name: pst_post_usertags pst_post_usertags_post_id_userprofile_id_3a894e13_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_usertags
    ADD CONSTRAINT pst_post_usertags_post_id_userprofile_id_3a894e13_uniq UNIQUE (post_id, userprofile_id);


--
-- Name: pst_votepost pst_votepost_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_votepost
    ADD CONSTRAINT pst_votepost_pkey PRIMARY KEY (post_ptr_id);


--
-- Name: upload_fileupload upload_fileupload_media_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.upload_fileupload
    ADD CONSTRAINT upload_fileupload_media_key_key UNIQUE (media_key);


--
-- Name: upload_fileupload upload_fileupload_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.upload_fileupload
    ADD CONSTRAINT upload_fileupload_pkey PRIMARY KEY (id);


--
-- Name: accounts_fe_created_75d4b9_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_fe_created_75d4b9_brin ON public.accounts_feedback USING brin (created);


--
-- Name: accounts_feedback_updated_2948a09e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_feedback_updated_2948a09e ON public.accounts_feedback USING btree (updated);


--
-- Name: accounts_in_created_94cfe9_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_in_created_94cfe9_brin ON public.accounts_invites USING brin (created);


--
-- Name: accounts_invites_user_id_f8798e32; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_invites_user_id_f8798e32 ON public.accounts_invites USING btree (user_id);


--
-- Name: accounts_userfeedback_user_id_00952b3e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userfeedback_user_id_00952b3e ON public.accounts_userfeedback USING btree (user_id);


--
-- Name: accounts_userprofile_blocked_from_userprofile_id_355dc595; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_blocked_from_userprofile_id_355dc595 ON public.accounts_userprofile_blocked USING btree (from_userprofile_id);


--
-- Name: accounts_userprofile_blocked_to_userprofile_id_53778445; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_blocked_to_userprofile_id_53778445 ON public.accounts_userprofile_blocked USING btree (to_userprofile_id);


--
-- Name: accounts_userprofile_close_friends_from_userprofile_id_f1393c0b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_close_friends_from_userprofile_id_f1393c0b ON public.accounts_userprofile_close_friends USING btree (from_userprofile_id);


--
-- Name: accounts_userprofile_close_friends_to_userprofile_id_f0a3b464; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_close_friends_to_userprofile_id_f0a3b464 ON public.accounts_userprofile_close_friends USING btree (to_userprofile_id);


--
-- Name: accounts_userprofile_follows_from_userprofile_id_2798b703; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_follows_from_userprofile_id_2798b703 ON public.accounts_userprofile_follows USING btree (from_userprofile_id);


--
-- Name: accounts_userprofile_follows_to_userprofile_id_c73d9228; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_follows_to_userprofile_id_c73d9228 ON public.accounts_userprofile_follows USING btree (to_userprofile_id);


--
-- Name: accounts_userprofile_groups_group_id_74ae51cf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_groups_group_id_74ae51cf ON public.accounts_userprofile_groups USING btree (group_id);


--
-- Name: accounts_userprofile_groups_userprofile_id_b7fb6469; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_groups_userprofile_id_b7fb6469 ON public.accounts_userprofile_groups USING btree (userprofile_id);


--
-- Name: accounts_userprofile_phone_8e09b259_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_phone_8e09b259_like ON public.accounts_userprofile USING btree (phone varchar_pattern_ops);


--
-- Name: accounts_userprofile_user_permissions_permission_id_a9b2b32b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_user_permissions_permission_id_a9b2b32b ON public.accounts_userprofile_user_permissions USING btree (permission_id);


--
-- Name: accounts_userprofile_user_permissions_userprofile_id_4acaf5a0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_user_permissions_userprofile_id_4acaf5a0 ON public.accounts_userprofile_user_permissions USING btree (userprofile_id);


--
-- Name: accounts_userprofile_user_real_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_user_real_location_id ON public.accounts_userprofile USING gist (user_real_location);


--
-- Name: accounts_userprofile_user_safe_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_user_safe_location_id ON public.accounts_userprofile USING gist (user_safe_location);


--
-- Name: accounts_userprofile_username_8e8bc851_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX accounts_userprofile_username_8e8bc851_like ON public.accounts_userprofile USING btree (username varchar_pattern_ops);


--
-- Name: actstream_action_action_object_content_type_id_ee623c15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_action_object_content_type_id_ee623c15 ON public.actstream_action USING btree (action_object_content_type_id);


--
-- Name: actstream_action_action_object_object_id_6433bdf7; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_action_object_object_id_6433bdf7 ON public.actstream_action USING btree (action_object_object_id);


--
-- Name: actstream_action_action_object_object_id_6433bdf7_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_action_object_object_id_6433bdf7_like ON public.actstream_action USING btree (action_object_object_id varchar_pattern_ops);


--
-- Name: actstream_action_actor_content_type_id_d5e5ec2a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_actor_content_type_id_d5e5ec2a ON public.actstream_action USING btree (actor_content_type_id);


--
-- Name: actstream_action_actor_object_id_72ef0cfa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_actor_object_id_72ef0cfa ON public.actstream_action USING btree (actor_object_id);


--
-- Name: actstream_action_actor_object_id_72ef0cfa_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_actor_object_id_72ef0cfa_like ON public.actstream_action USING btree (actor_object_id varchar_pattern_ops);


--
-- Name: actstream_action_public_ac0653e9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_public_ac0653e9 ON public.actstream_action USING btree (public);


--
-- Name: actstream_action_target_content_type_id_187fa164; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_target_content_type_id_187fa164 ON public.actstream_action USING btree (target_content_type_id);


--
-- Name: actstream_action_target_object_id_e080d801; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_target_object_id_e080d801 ON public.actstream_action USING btree (target_object_id);


--
-- Name: actstream_action_target_object_id_e080d801_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_target_object_id_e080d801_like ON public.actstream_action USING btree (target_object_id varchar_pattern_ops);


--
-- Name: actstream_action_timestamp_a23fe3ae; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_timestamp_a23fe3ae ON public.actstream_action USING btree ("timestamp");


--
-- Name: actstream_action_verb_83f768b7; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_verb_83f768b7 ON public.actstream_action USING btree (verb);


--
-- Name: actstream_action_verb_83f768b7_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_action_verb_83f768b7_like ON public.actstream_action USING btree (verb varchar_pattern_ops);


--
-- Name: actstream_follow_content_type_id_ba287eb9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_follow_content_type_id_ba287eb9 ON public.actstream_follow USING btree (content_type_id);


--
-- Name: actstream_follow_object_id_d790e00d; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_follow_object_id_d790e00d ON public.actstream_follow USING btree (object_id);


--
-- Name: actstream_follow_object_id_d790e00d_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_follow_object_id_d790e00d_like ON public.actstream_follow USING btree (object_id varchar_pattern_ops);


--
-- Name: actstream_follow_started_254c63bd; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_follow_started_254c63bd ON public.actstream_follow USING btree (started);


--
-- Name: actstream_follow_user_id_e9d4e1ff; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX actstream_follow_user_id_e9d4e1ff ON public.actstream_follow USING btree (user_id);


--
-- Name: appnotifica_created_98e6fb_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX appnotifica_created_98e6fb_brin ON public.appnotifications_device USING brin (created);


--
-- Name: appnotifications_device_token_6765efeb_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX appnotifications_device_token_6765efeb_like ON public.appnotifications_device USING btree (token varchar_pattern_ops);


--
-- Name: appnotifications_device_updated_f0473e4e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX appnotifications_device_updated_f0473e4e ON public.appnotifications_device USING btree (updated);


--
-- Name: appnotifications_device_user_id_e281be8a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX appnotifications_device_user_id_e281be8a ON public.appnotifications_device USING btree (user_id);


--
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- Name: authtoken_token_key_10f0b77e_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX authtoken_token_key_10f0b77e_like ON public.authtoken_token USING btree (key varchar_pattern_ops);


--
-- Name: chat_messag_created_aeee25_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_messag_created_aeee25_brin ON public.chat_message USING brin (created);


--
-- Name: chat_message_forwarded_message_id_3a06f552; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_forwarded_message_id_3a06f552 ON public.chat_message USING btree (forwarded_message_id);


--
-- Name: chat_message_hashtags_interest_id_3116b459; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_hashtags_interest_id_3116b459 ON public.chat_message_hashtags USING btree (interest_id);


--
-- Name: chat_message_hashtags_message_id_80415300; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_hashtags_message_id_80415300 ON public.chat_message_hashtags USING btree (message_id);


--
-- Name: chat_message_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_location_id ON public.chat_message USING gist (location);


--
-- Name: chat_message_parent_id_d93c704f; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_parent_id_d93c704f ON public.chat_message USING btree (parent_id);


--
-- Name: chat_message_private_post_id_6d25fa85; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_private_post_id_6d25fa85 ON public.chat_message USING btree (private_post_id);


--
-- Name: chat_message_room_id_5e7d8d78; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_room_id_5e7d8d78 ON public.chat_message USING btree (room_id);


--
-- Name: chat_message_user_id_a47c01bb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_user_id_a47c01bb ON public.chat_message USING btree (user_id);


--
-- Name: chat_message_users_seen_message_message_id_1aab0396; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_users_seen_message_message_id_1aab0396 ON public.chat_message_users_seen_message USING btree (message_id);


--
-- Name: chat_message_users_seen_message_userprofile_id_5ebf085a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_users_seen_message_userprofile_id_5ebf085a ON public.chat_message_users_seen_message USING btree (userprofile_id);


--
-- Name: chat_message_usertags_message_id_d0800f83; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_usertags_message_id_d0800f83 ON public.chat_message_usertags USING btree (message_id);


--
-- Name: chat_message_usertags_userprofile_id_cd5bebf2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_message_usertags_userprofile_id_cd5bebf2 ON public.chat_message_usertags USING btree (userprofile_id);


--
-- Name: chat_room_administrators_room_id_6134c811; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_administrators_room_id_6134c811 ON public.chat_room_administrators USING btree (room_id);


--
-- Name: chat_room_administrators_userprofile_id_6418a5d0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_administrators_userprofile_id_6418a5d0 ON public.chat_room_administrators USING btree (userprofile_id);


--
-- Name: chat_room_created_b2a944_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_created_b2a944_brin ON public.chat_room USING brin (created);


--
-- Name: chat_room_interests_interest_id_0bfbb1df; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_interests_interest_id_0bfbb1df ON public.chat_room_interests USING btree (interest_id);


--
-- Name: chat_room_interests_room_id_505611e6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_interests_room_id_505611e6 ON public.chat_room_interests USING btree (room_id);


--
-- Name: chat_room_key_303adb51_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_key_303adb51_like ON public.chat_room USING btree (key varchar_pattern_ops);


--
-- Name: chat_room_last_interaction_068cbf9a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_last_interaction_068cbf9a ON public.chat_room USING btree (last_interaction);


--
-- Name: chat_room_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_location_id ON public.chat_room USING gist (location);


--
-- Name: chat_room_pending_room_id_8c602597; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_pending_room_id_8c602597 ON public.chat_room_pending USING btree (room_id);


--
-- Name: chat_room_pending_userprofile_id_4702fab9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_pending_userprofile_id_4702fab9 ON public.chat_room_pending USING btree (userprofile_id);


--
-- Name: chat_room_place_id_6f634c49; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_place_id_6f634c49 ON public.chat_room USING btree (place_id);


--
-- Name: chat_room_safe_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_safe_location_id ON public.chat_room USING gist (safe_location);


--
-- Name: chat_room_users_room_id_4cd79c94; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_users_room_id_4cd79c94 ON public.chat_room_users USING btree (room_id);


--
-- Name: chat_room_users_userprofile_id_fa87db1d; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX chat_room_users_userprofile_id_fa87db1d ON public.chat_room_users USING btree (userprofile_id);


--
-- Name: comments_co_created_9b07c7_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_co_created_9b07c7_brin ON public.comments_comments USING brin (created);


--
-- Name: comments_comments_downvotes_comments_id_19dfd0d1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_downvotes_comments_id_19dfd0d1 ON public.comments_comments_downvotes USING btree (comments_id);


--
-- Name: comments_comments_downvotes_userprofile_id_492cc36e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_downvotes_userprofile_id_492cc36e ON public.comments_comments_downvotes USING btree (userprofile_id);


--
-- Name: comments_comments_hashtags_comments_id_1bff845c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_hashtags_comments_id_1bff845c ON public.comments_comments_hashtags USING btree (comments_id);


--
-- Name: comments_comments_hashtags_interest_id_c9f06d38; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_hashtags_interest_id_c9f06d38 ON public.comments_comments_hashtags USING btree (interest_id);


--
-- Name: comments_comments_parent_id_d9fe1944; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_parent_id_d9fe1944 ON public.comments_comments USING btree (parent_id);


--
-- Name: comments_comments_post_id_59c014a0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_post_id_59c014a0 ON public.comments_comments USING btree (post_id);


--
-- Name: comments_comments_updated_226efd73; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_updated_226efd73 ON public.comments_comments USING btree (updated);


--
-- Name: comments_comments_upvotes_comments_id_8fe88db6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_upvotes_comments_id_8fe88db6 ON public.comments_comments_upvotes USING btree (comments_id);


--
-- Name: comments_comments_upvotes_userprofile_id_aa67ec5b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_upvotes_userprofile_id_aa67ec5b ON public.comments_comments_upvotes USING btree (userprofile_id);


--
-- Name: comments_comments_user_id_d2c0ea69; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_user_id_d2c0ea69 ON public.comments_comments USING btree (user_id);


--
-- Name: comments_comments_usertags_comments_id_9dd69a72; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_usertags_comments_id_9dd69a72 ON public.comments_comments_usertags USING btree (comments_id);


--
-- Name: comments_comments_usertags_userprofile_id_8548bbde; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_comments_usertags_userprofile_id_8548bbde ON public.comments_comments_usertags USING btree (userprofile_id);


--
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- Name: django_site_domain_a2e37b91_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_site_domain_a2e37b91_like ON public.django_site USING btree (domain varchar_pattern_ops);


--
-- Name: interests_i_created_c37ac9_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interests_i_created_c37ac9_brin ON public.interests_interest USING brin (created);


--
-- Name: interests_interest_name_4855d67c_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interests_interest_name_4855d67c_like ON public.interests_interest USING btree (name varchar_pattern_ops);


--
-- Name: interests_interest_updated_2037ab01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interests_interest_updated_2037ab01 ON public.interests_interest USING btree (updated);


--
-- Name: interests_u_created_9d3705_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interests_u_created_9d3705_brin ON public.interests_userinterest USING brin (created);


--
-- Name: interests_userinterest_updated_61ca93b3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX interests_userinterest_updated_61ca93b3 ON public.interests_userinterest USING btree (updated);


--
-- Name: notifications_notification_action_object_content_type_7d2b8ee9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notifications_notification_action_object_content_type_7d2b8ee9 ON public.notifications_notification USING btree (action_object_content_type_id);


--
-- Name: notifications_notification_actor_content_type_id_0c69d7b7; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notifications_notification_actor_content_type_id_0c69d7b7 ON public.notifications_notification USING btree (actor_content_type_id);


--
-- Name: notifications_notification_recipient_id_d055f3f0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notifications_notification_recipient_id_d055f3f0 ON public.notifications_notification USING btree (recipient_id);


--
-- Name: notifications_notification_target_content_type_id_ccb24d88; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notifications_notification_target_content_type_id_ccb24d88 ON public.notifications_notification USING btree (target_content_type_id);


--
-- Name: places_plac_created_270557_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX places_plac_created_270557_brin ON public.places_place USING brin (created);


--
-- Name: places_place_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX places_place_location_id ON public.places_place USING gist (location);


--
-- Name: places_place_place_id_71bca539_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX places_place_place_id_71bca539_like ON public.places_place USING btree (place_id varchar_pattern_ops);


--
-- Name: places_place_types_place_id_47b9e044; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX places_place_types_place_id_47b9e044 ON public.places_place_types USING btree (place_id);


--
-- Name: places_place_types_placetype_id_85b39e33; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX places_place_types_placetype_id_85b39e33 ON public.places_place_types USING btree (placetype_id);


--
-- Name: places_place_updated_49186d6e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX places_place_updated_49186d6e ON public.places_place USING btree (updated);


--
-- Name: places_placetype_name_647ccf56_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX places_placetype_name_647ccf56_like ON public.places_placetype USING btree (name varchar_pattern_ops);


--
-- Name: pst_event_attendees_event_id_48992b46; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_event_attendees_event_id_48992b46 ON public.pst_event_attendees USING btree (event_id);


--
-- Name: pst_event_attendees_userprofile_id_1875941a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_event_attendees_userprofile_id_1875941a ON public.pst_event_attendees USING btree (userprofile_id);


--
-- Name: pst_event_event_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_event_event_location_id ON public.pst_event USING gist (event_location);


--
-- Name: pst_pollitem_poll_id_f1b7e105; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_pollitem_poll_id_f1b7e105 ON public.pst_pollitem USING btree (poll_id);


--
-- Name: pst_pollitem_votes_pollitem_id_b5de4d10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_pollitem_votes_pollitem_id_b5de4d10 ON public.pst_pollitem_votes USING btree (pollitem_id);


--
-- Name: pst_pollitem_votes_userprofile_id_ec0cf0db; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_pollitem_votes_userprofile_id_ec0cf0db ON public.pst_pollitem_votes USING btree (userprofile_id);


--
-- Name: pst_post_created_ad7836_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_created_ad7836_brin ON public.pst_post USING brin (created);


--
-- Name: pst_post_downvotes_post_id_8839e208; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_downvotes_post_id_8839e208 ON public.pst_post_downvotes USING btree (post_id);


--
-- Name: pst_post_downvotes_userprofile_id_905c2f5c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_downvotes_userprofile_id_905c2f5c ON public.pst_post_downvotes USING btree (userprofile_id);


--
-- Name: pst_post_fake_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_fake_location_id ON public.pst_post USING gist (fake_location);


--
-- Name: pst_post_hashtags_interest_id_d1ac07a7; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_hashtags_interest_id_d1ac07a7 ON public.pst_post_hashtags USING btree (interest_id);


--
-- Name: pst_post_hashtags_post_id_efc6b901; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_hashtags_post_id_efc6b901 ON public.pst_post_hashtags USING btree (post_id);


--
-- Name: pst_post_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_location_id ON public.pst_post USING gist (location);


--
-- Name: pst_post_parent_id_ea994a8f; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_parent_id_ea994a8f ON public.pst_post USING btree (parent_id);


--
-- Name: pst_post_place_id_cc2ba08c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_place_id_cc2ba08c ON public.pst_post USING btree (place_id);


--
-- Name: pst_post_private_39dd3139; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_private_39dd3139 ON public.pst_post USING btree (private);


--
-- Name: pst_post_updated_67e49ebe; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_updated_67e49ebe ON public.pst_post USING btree (updated);


--
-- Name: pst_post_upvotes_post_id_46b87290; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_upvotes_post_id_46b87290 ON public.pst_post_upvotes USING btree (post_id);


--
-- Name: pst_post_upvotes_userprofile_id_a9186571; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_upvotes_userprofile_id_a9186571 ON public.pst_post_upvotes USING btree (userprofile_id);


--
-- Name: pst_post_user_id_3a8be664; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_user_id_3a8be664 ON public.pst_post USING btree (user_id);


--
-- Name: pst_post_usertags_post_id_337c0c95; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_usertags_post_id_337c0c95 ON public.pst_post_usertags USING btree (post_id);


--
-- Name: pst_post_usertags_userprofile_id_ddca37b9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pst_post_usertags_userprofile_id_ddca37b9 ON public.pst_post_usertags USING btree (userprofile_id);


--
-- Name: upload_file_created_8b16cf_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX upload_file_created_8b16cf_brin ON public.upload_fileupload USING brin (created);


--
-- Name: upload_fileupload_media_key_5622af41_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX upload_fileupload_media_key_5622af41_like ON public.upload_fileupload USING btree (media_key varchar_pattern_ops);


--
-- Name: upload_fileupload_owner_id_611a575b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX upload_fileupload_owner_id_611a575b ON public.upload_fileupload USING btree (owner_id);


--
-- Name: upload_fileupload_updated_b23f70c7; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX upload_fileupload_updated_b23f70c7 ON public.upload_fileupload USING btree (updated);


--
-- Name: accounts_invites accounts_invites_user_id_f8798e32_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_invites
    ADD CONSTRAINT accounts_invites_user_id_f8798e32_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userfeedback accounts_userfeedbac_feedback_ptr_id_654743c0_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userfeedback
    ADD CONSTRAINT accounts_userfeedbac_feedback_ptr_id_654743c0_fk_accounts_ FOREIGN KEY (feedback_ptr_id) REFERENCES public.accounts_feedback(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userfeedback accounts_userfeedbac_user_id_00952b3e_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userfeedback
    ADD CONSTRAINT accounts_userfeedbac_user_id_00952b3e_fk_accounts_ FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_follows accounts_userprofile_from_userprofile_id_2798b703_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_follows
    ADD CONSTRAINT accounts_userprofile_from_userprofile_id_2798b703_fk_accounts_ FOREIGN KEY (from_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_blocked accounts_userprofile_from_userprofile_id_355dc595_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_blocked
    ADD CONSTRAINT accounts_userprofile_from_userprofile_id_355dc595_fk_accounts_ FOREIGN KEY (from_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_close_friends accounts_userprofile_from_userprofile_id_f1393c0b_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_close_friends
    ADD CONSTRAINT accounts_userprofile_from_userprofile_id_f1393c0b_fk_accounts_ FOREIGN KEY (from_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_groups accounts_userprofile_groups_group_id_74ae51cf_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_groups
    ADD CONSTRAINT accounts_userprofile_groups_group_id_74ae51cf_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_user_permissions accounts_userprofile_permission_id_a9b2b32b_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_user_permissions
    ADD CONSTRAINT accounts_userprofile_permission_id_a9b2b32b_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_blocked accounts_userprofile_to_userprofile_id_53778445_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_blocked
    ADD CONSTRAINT accounts_userprofile_to_userprofile_id_53778445_fk_accounts_ FOREIGN KEY (to_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_follows accounts_userprofile_to_userprofile_id_c73d9228_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_follows
    ADD CONSTRAINT accounts_userprofile_to_userprofile_id_c73d9228_fk_accounts_ FOREIGN KEY (to_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_close_friends accounts_userprofile_to_userprofile_id_f0a3b464_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_close_friends
    ADD CONSTRAINT accounts_userprofile_to_userprofile_id_f0a3b464_fk_accounts_ FOREIGN KEY (to_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_user_permissions accounts_userprofile_userprofile_id_4acaf5a0_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_user_permissions
    ADD CONSTRAINT accounts_userprofile_userprofile_id_4acaf5a0_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_groups accounts_userprofile_userprofile_id_b7fb6469_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts_userprofile_groups
    ADD CONSTRAINT accounts_userprofile_userprofile_id_b7fb6469_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: actstream_action actstream_action_action_object_conten_ee623c15_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actstream_action
    ADD CONSTRAINT actstream_action_action_object_conten_ee623c15_fk_django_co FOREIGN KEY (action_object_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: actstream_action actstream_action_actor_content_type_i_d5e5ec2a_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actstream_action
    ADD CONSTRAINT actstream_action_actor_content_type_i_d5e5ec2a_fk_django_co FOREIGN KEY (actor_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: actstream_action actstream_action_target_content_type__187fa164_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actstream_action
    ADD CONSTRAINT actstream_action_target_content_type__187fa164_fk_django_co FOREIGN KEY (target_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: actstream_follow actstream_follow_content_type_id_ba287eb9_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actstream_follow
    ADD CONSTRAINT actstream_follow_content_type_id_ba287eb9_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: actstream_follow actstream_follow_user_id_e9d4e1ff_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actstream_follow
    ADD CONSTRAINT actstream_follow_user_id_e9d4e1ff_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: appnotifications_device appnotifications_dev_user_id_e281be8a_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appnotifications_device
    ADD CONSTRAINT appnotifications_dev_user_id_e281be8a_fk_accounts_ FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: authtoken_token authtoken_token_user_id_35299eff_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_user_id_35299eff_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message chat_message_forwarded_message_id_3a06f552_fk_chat_message_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_forwarded_message_id_3a06f552_fk_chat_message_id FOREIGN KEY (forwarded_message_id) REFERENCES public.chat_message(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_hashtags chat_message_hashtag_interest_id_3116b459_fk_interests; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_hashtags
    ADD CONSTRAINT chat_message_hashtag_interest_id_3116b459_fk_interests FOREIGN KEY (interest_id) REFERENCES public.interests_interest(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_hashtags chat_message_hashtags_message_id_80415300_fk_chat_message_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_hashtags
    ADD CONSTRAINT chat_message_hashtags_message_id_80415300_fk_chat_message_id FOREIGN KEY (message_id) REFERENCES public.chat_message(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message chat_message_parent_id_d93c704f_fk_chat_message_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_parent_id_d93c704f_fk_chat_message_id FOREIGN KEY (parent_id) REFERENCES public.chat_message(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message chat_message_private_post_id_6d25fa85_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_private_post_id_6d25fa85_fk_pst_post_id FOREIGN KEY (private_post_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message chat_message_room_id_5e7d8d78_fk_chat_room_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_room_id_5e7d8d78_fk_chat_room_id FOREIGN KEY (room_id) REFERENCES public.chat_room(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message chat_message_user_id_a47c01bb_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_user_id_a47c01bb_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_users_seen_message chat_message_users_s_message_id_1aab0396_fk_chat_mess; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_users_seen_message
    ADD CONSTRAINT chat_message_users_s_message_id_1aab0396_fk_chat_mess FOREIGN KEY (message_id) REFERENCES public.chat_message(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_users_seen_message chat_message_users_s_userprofile_id_5ebf085a_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_users_seen_message
    ADD CONSTRAINT chat_message_users_s_userprofile_id_5ebf085a_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_usertags chat_message_usertag_userprofile_id_cd5bebf2_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_usertags
    ADD CONSTRAINT chat_message_usertag_userprofile_id_cd5bebf2_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_usertags chat_message_usertags_message_id_d0800f83_fk_chat_message_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_usertags
    ADD CONSTRAINT chat_message_usertags_message_id_d0800f83_fk_chat_message_id FOREIGN KEY (message_id) REFERENCES public.chat_message(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_administrators chat_room_administra_userprofile_id_6418a5d0_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_administrators
    ADD CONSTRAINT chat_room_administra_userprofile_id_6418a5d0_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_administrators chat_room_administrators_room_id_6134c811_fk_chat_room_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_administrators
    ADD CONSTRAINT chat_room_administrators_room_id_6134c811_fk_chat_room_id FOREIGN KEY (room_id) REFERENCES public.chat_room(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room chat_room_interest_id_c29af3f3_fk_interests_interest_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room
    ADD CONSTRAINT chat_room_interest_id_c29af3f3_fk_interests_interest_id FOREIGN KEY (interest_id) REFERENCES public.interests_interest(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_interests chat_room_interests_interest_id_0bfbb1df_fk_interests; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_interests
    ADD CONSTRAINT chat_room_interests_interest_id_0bfbb1df_fk_interests FOREIGN KEY (interest_id) REFERENCES public.interests_interest(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_interests chat_room_interests_room_id_505611e6_fk_chat_room_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_interests
    ADD CONSTRAINT chat_room_interests_room_id_505611e6_fk_chat_room_id FOREIGN KEY (room_id) REFERENCES public.chat_room(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_pending chat_room_pending_room_id_8c602597_fk_chat_room_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_pending
    ADD CONSTRAINT chat_room_pending_room_id_8c602597_fk_chat_room_id FOREIGN KEY (room_id) REFERENCES public.chat_room(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_pending chat_room_pending_userprofile_id_4702fab9_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_pending
    ADD CONSTRAINT chat_room_pending_userprofile_id_4702fab9_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room chat_room_place_id_6f634c49_fk_places_place_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room
    ADD CONSTRAINT chat_room_place_id_6f634c49_fk_places_place_id FOREIGN KEY (place_id) REFERENCES public.places_place(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_users chat_room_users_room_id_4cd79c94_fk_chat_room_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_users
    ADD CONSTRAINT chat_room_users_room_id_4cd79c94_fk_chat_room_id FOREIGN KEY (room_id) REFERENCES public.chat_room(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_users chat_room_users_userprofile_id_fa87db1d_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_room_users
    ADD CONSTRAINT chat_room_users_userprofile_id_fa87db1d_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_downvotes comments_comments_do_comments_id_19dfd0d1_fk_comments_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_downvotes
    ADD CONSTRAINT comments_comments_do_comments_id_19dfd0d1_fk_comments_ FOREIGN KEY (comments_id) REFERENCES public.comments_comments(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_downvotes comments_comments_do_userprofile_id_492cc36e_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_downvotes
    ADD CONSTRAINT comments_comments_do_userprofile_id_492cc36e_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_hashtags comments_comments_ha_comments_id_1bff845c_fk_comments_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_hashtags
    ADD CONSTRAINT comments_comments_ha_comments_id_1bff845c_fk_comments_ FOREIGN KEY (comments_id) REFERENCES public.comments_comments(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_hashtags comments_comments_ha_interest_id_c9f06d38_fk_interests; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_hashtags
    ADD CONSTRAINT comments_comments_ha_interest_id_c9f06d38_fk_interests FOREIGN KEY (interest_id) REFERENCES public.interests_interest(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments comments_comments_parent_id_d9fe1944_fk_comments_comments_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments
    ADD CONSTRAINT comments_comments_parent_id_d9fe1944_fk_comments_comments_id FOREIGN KEY (parent_id) REFERENCES public.comments_comments(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments comments_comments_post_id_59c014a0_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments
    ADD CONSTRAINT comments_comments_post_id_59c014a0_fk_pst_post_id FOREIGN KEY (post_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_upvotes comments_comments_up_comments_id_8fe88db6_fk_comments_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_upvotes
    ADD CONSTRAINT comments_comments_up_comments_id_8fe88db6_fk_comments_ FOREIGN KEY (comments_id) REFERENCES public.comments_comments(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_upvotes comments_comments_up_userprofile_id_aa67ec5b_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_upvotes
    ADD CONSTRAINT comments_comments_up_userprofile_id_aa67ec5b_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_usertags comments_comments_us_comments_id_9dd69a72_fk_comments_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_usertags
    ADD CONSTRAINT comments_comments_us_comments_id_9dd69a72_fk_comments_ FOREIGN KEY (comments_id) REFERENCES public.comments_comments(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_usertags comments_comments_us_userprofile_id_8548bbde_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments_usertags
    ADD CONSTRAINT comments_comments_us_userprofile_id_8548bbde_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments comments_comments_user_id_d2c0ea69_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments_comments
    ADD CONSTRAINT comments_comments_user_id_d2c0ea69_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_user_id_c564eba6_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: interests_userinterest interests_userintere_interest_id_9ab9062c_fk_interests; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interests_userinterest
    ADD CONSTRAINT interests_userintere_interest_id_9ab9062c_fk_interests FOREIGN KEY (interest_id) REFERENCES public.interests_interest(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: interests_userinterest interests_userintere_user_id_bffd376a_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interests_userinterest
    ADD CONSTRAINT interests_userintere_user_id_bffd376a_fk_accounts_ FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: notifications_notification notifications_notifi_action_object_conten_7d2b8ee9_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notifi_action_object_conten_7d2b8ee9_fk_django_co FOREIGN KEY (action_object_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: notifications_notification notifications_notifi_actor_content_type_i_0c69d7b7_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notifi_actor_content_type_i_0c69d7b7_fk_django_co FOREIGN KEY (actor_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: notifications_notification notifications_notifi_recipient_id_d055f3f0_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notifi_recipient_id_d055f3f0_fk_accounts_ FOREIGN KEY (recipient_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: notifications_notification notifications_notifi_target_content_type__ccb24d88_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notifi_target_content_type__ccb24d88_fk_django_co FOREIGN KEY (target_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: places_place_types places_place_types_place_id_47b9e044_fk_places_place_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places_place_types
    ADD CONSTRAINT places_place_types_place_id_47b9e044_fk_places_place_id FOREIGN KEY (place_id) REFERENCES public.places_place(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: places_place_types places_place_types_placetype_id_85b39e33_fk_places_placetype_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.places_place_types
    ADD CONSTRAINT places_place_types_placetype_id_85b39e33_fk_places_placetype_id FOREIGN KEY (placetype_id) REFERENCES public.places_placetype(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_event_attendees pst_event_attendees_event_id_48992b46_fk_pst_event_post_ptr_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_event_attendees
    ADD CONSTRAINT pst_event_attendees_event_id_48992b46_fk_pst_event_post_ptr_id FOREIGN KEY (event_id) REFERENCES public.pst_event(post_ptr_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_event_attendees pst_event_attendees_userprofile_id_1875941a_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_event_attendees
    ADD CONSTRAINT pst_event_attendees_userprofile_id_1875941a_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_event pst_event_post_ptr_id_77bcaabd_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_event
    ADD CONSTRAINT pst_event_post_ptr_id_77bcaabd_fk_pst_post_id FOREIGN KEY (post_ptr_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_poll pst_poll_post_ptr_id_0b510052_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_poll
    ADD CONSTRAINT pst_poll_post_ptr_id_0b510052_fk_pst_post_id FOREIGN KEY (post_ptr_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_pollitem pst_pollitem_poll_id_f1b7e105_fk_pst_poll_post_ptr_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_pollitem
    ADD CONSTRAINT pst_pollitem_poll_id_f1b7e105_fk_pst_poll_post_ptr_id FOREIGN KEY (poll_id) REFERENCES public.pst_poll(post_ptr_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_pollitem_votes pst_pollitem_votes_pollitem_id_b5de4d10_fk_pst_pollitem_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_pollitem_votes
    ADD CONSTRAINT pst_pollitem_votes_pollitem_id_b5de4d10_fk_pst_pollitem_id FOREIGN KEY (pollitem_id) REFERENCES public.pst_pollitem(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_pollitem_votes pst_pollitem_votes_userprofile_id_ec0cf0db_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_pollitem_votes
    ADD CONSTRAINT pst_pollitem_votes_userprofile_id_ec0cf0db_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_downvotes pst_post_downvotes_post_id_8839e208_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_downvotes
    ADD CONSTRAINT pst_post_downvotes_post_id_8839e208_fk_pst_post_id FOREIGN KEY (post_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_downvotes pst_post_downvotes_userprofile_id_905c2f5c_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_downvotes
    ADD CONSTRAINT pst_post_downvotes_userprofile_id_905c2f5c_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_hashtags pst_post_hashtags_interest_id_d1ac07a7_fk_interests_interest_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_hashtags
    ADD CONSTRAINT pst_post_hashtags_interest_id_d1ac07a7_fk_interests_interest_id FOREIGN KEY (interest_id) REFERENCES public.interests_interest(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_hashtags pst_post_hashtags_post_id_efc6b901_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_hashtags
    ADD CONSTRAINT pst_post_hashtags_post_id_efc6b901_fk_pst_post_id FOREIGN KEY (post_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post pst_post_parent_id_ea994a8f_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post
    ADD CONSTRAINT pst_post_parent_id_ea994a8f_fk_pst_post_id FOREIGN KEY (parent_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post pst_post_place_id_cc2ba08c_fk_places_place_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post
    ADD CONSTRAINT pst_post_place_id_cc2ba08c_fk_places_place_id FOREIGN KEY (place_id) REFERENCES public.places_place(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_upvotes pst_post_upvotes_post_id_46b87290_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_upvotes
    ADD CONSTRAINT pst_post_upvotes_post_id_46b87290_fk_pst_post_id FOREIGN KEY (post_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_upvotes pst_post_upvotes_userprofile_id_a9186571_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_upvotes
    ADD CONSTRAINT pst_post_upvotes_userprofile_id_a9186571_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post pst_post_user_id_3a8be664_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post
    ADD CONSTRAINT pst_post_user_id_3a8be664_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_usertags pst_post_usertags_post_id_337c0c95_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_usertags
    ADD CONSTRAINT pst_post_usertags_post_id_337c0c95_fk_pst_post_id FOREIGN KEY (post_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_usertags pst_post_usertags_userprofile_id_ddca37b9_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_post_usertags
    ADD CONSTRAINT pst_post_usertags_userprofile_id_ddca37b9_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_votepost pst_votepost_post_ptr_id_b1c474f2_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pst_votepost
    ADD CONSTRAINT pst_votepost_post_ptr_id_b1c474f2_fk_pst_post_id FOREIGN KEY (post_ptr_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: upload_fileupload upload_fileupload_owner_id_611a575b_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.upload_fileupload
    ADD CONSTRAINT upload_fileupload_owner_id_611a575b_fk_accounts_userprofile_id FOREIGN KEY (owner_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- PostgreSQL database dump complete
--
