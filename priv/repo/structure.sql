--
-- PostgreSQL database dump
--

-- Dumped from database version 11.2
-- Dumped by pg_dump version 12.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: events_tsvector_update_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.events_tsvector_update_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.tsvector := to_tsvector('pg_catalog.english', new.body);
  return new;
end
$$;


--
-- Name: polls_tsvector_update_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.polls_tsvector_update_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.tsvector := to_tsvector('pg_catalog.english', new.question);
  return new;
end
$$;


--
-- Name: posts_comments_tsvector_update_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.posts_comments_tsvector_update_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.tsvector := to_tsvector('pg_catalog.english', new.body);
  return new;
end
$$;


--
-- Name: posts_tsvector_update_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.posts_tsvector_update_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.tsvector := to_tsvector('pg_catalog.english', new.body);
  return new;
end
$$;


--
-- Name: pst_post_tsv_update_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pst_post_tsv_update_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.tsv := to_tsvector('pg_catalog.english', new.body);
  return new;
end
$$;


SET default_tablespace = '';

--
-- Name: accounts_feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_feedback (
    id integer NOT NULL,
    feedback_type character varying(100) NOT NULL,
    message text NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    feedback_image character varying(100) NOT NULL
);


--
-- Name: accounts_feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_feedback_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_feedback_id_seq OWNED BY public.accounts_feedback.id;


--
-- Name: accounts_invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_invites (
    id integer NOT NULL,
    email character varying(254) NOT NULL,
    created timestamp with time zone NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: accounts_invites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_invites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_invites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_invites_id_seq OWNED BY public.accounts_invites.id;


--
-- Name: accounts_membership; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_membership (
    id bigint NOT NULL,
    business_account_id bigint NOT NULL,
    member_id bigint NOT NULL,
    role character varying(255) NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    required_approval boolean DEFAULT true
);


--
-- Name: accounts_membership_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_membership_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_membership_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_membership_id_seq OWNED BY public.accounts_membership.id;


--
-- Name: accounts_userfeedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_userfeedback (
    feedback_ptr_id integer NOT NULL,
    rating numeric(3,2) NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: accounts_userprofile; Type: TABLE; Schema: public; Owner: -
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
    phone text,
    verified_phone character varying(32),
    user_real_location public.geography(Point,4326),
    user_safe_location public.geography(Point,4326),
    enable_push_notifications boolean NOT NULL,
    verified_email character varying(254),
    area character varying(256) NOT NULL,
    is_business boolean DEFAULT false NOT NULL,
    eventbrite_id bigint,
    eventful_id character varying(255)
);


--
-- Name: accounts_userprofile_blocked; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_userprofile_blocked (
    id integer NOT NULL,
    from_userprofile_id integer NOT NULL,
    to_userprofile_id integer NOT NULL
);


--
-- Name: accounts_userprofile_blocked_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_userprofile_blocked_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_userprofile_blocked_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_userprofile_blocked_id_seq OWNED BY public.accounts_userprofile_blocked.id;


--
-- Name: accounts_userprofile_close_friends; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_userprofile_close_friends (
    id integer NOT NULL,
    from_userprofile_id integer NOT NULL,
    to_userprofile_id integer NOT NULL
);


--
-- Name: accounts_userprofile_close_friends_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_userprofile_close_friends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_userprofile_close_friends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_userprofile_close_friends_id_seq OWNED BY public.accounts_userprofile_close_friends.id;


--
-- Name: accounts_userprofile_follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_userprofile_follows (
    id integer NOT NULL,
    from_userprofile_id integer NOT NULL,
    to_userprofile_id integer NOT NULL
);


--
-- Name: accounts_userprofile_follows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_userprofile_follows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_userprofile_follows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_userprofile_follows_id_seq OWNED BY public.accounts_userprofile_follows.id;


--
-- Name: accounts_userprofile_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_userprofile_groups (
    id integer NOT NULL,
    userprofile_id integer NOT NULL,
    group_id integer NOT NULL
);


--
-- Name: accounts_userprofile_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_userprofile_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_userprofile_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_userprofile_groups_id_seq OWNED BY public.accounts_userprofile_groups.id;


--
-- Name: accounts_userprofile_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_userprofile_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_userprofile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_userprofile_id_seq OWNED BY public.accounts_userprofile.id;


--
-- Name: accounts_userprofile_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_userprofile_user_permissions (
    id integer NOT NULL,
    userprofile_id integer NOT NULL,
    permission_id integer NOT NULL
);


--
-- Name: accounts_userprofile_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_userprofile_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_userprofile_user_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_userprofile_user_permissions_id_seq OWNED BY public.accounts_userprofile_user_permissions.id;


--
-- Name: actstream_action; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: actstream_action_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.actstream_action_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: actstream_action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.actstream_action_id_seq OWNED BY public.actstream_action.id;


--
-- Name: actstream_follow; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.actstream_follow (
    id integer NOT NULL,
    object_id character varying(255) NOT NULL,
    actor_only boolean NOT NULL,
    started timestamp with time zone NOT NULL,
    content_type_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: actstream_follow_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.actstream_follow_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: actstream_follow_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.actstream_follow_id_seq OWNED BY public.actstream_follow.id;


--
-- Name: appnotifications_device; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appnotifications_device (
    id integer NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    platform character varying(7) NOT NULL,
    token character varying(255),
    user_id integer
);


--
-- Name: appnotifications_device_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appnotifications_device_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appnotifications_device_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appnotifications_device_id_seq OWNED BY public.appnotifications_device.id;


--
-- Name: auth_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(80) NOT NULL
);


--
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auth_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auth_group_id_seq OWNED BY public.auth_group.id;


--
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_group_permissions (
    id integer NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auth_group_permissions_id_seq OWNED BY public.auth_group_permissions.id;


--
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auth_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auth_permission_id_seq OWNED BY public.auth_permission.id;


--
-- Name: authtoken_token; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authtoken_token (
    key character varying NOT NULL,
    created timestamp with time zone NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: business_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_categories (
    id bigint NOT NULL,
    category_name character varying(255) NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL
);


--
-- Name: business_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.business_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: business_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.business_categories_id_seq OWNED BY public.business_categories.id;


--
-- Name: businesses_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.businesses_categories (
    id bigint NOT NULL,
    business_category_id bigint NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: businesses_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.businesses_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: businesses_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.businesses_categories_id_seq OWNED BY public.businesses_categories.id;


--
-- Name: change_password; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.change_password (
    id bigint NOT NULL,
    hash text NOT NULL,
    user_id bigint NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL
);


--
-- Name: change_password_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.change_password_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: change_password_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.change_password_id_seq OWNED BY public.change_password.id;


--
-- Name: chat_message; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_message (
    id integer NOT NULL,
    message text NOT NULL,
    created timestamp with time zone NOT NULL,
    room_id integer NOT NULL,
    user_id integer NOT NULL,
    location public.geography(Point,4326),
    message_type character varying(3) NOT NULL,
    parent_id integer,
    forwarded_message_id integer,
    edited timestamp with time zone,
    is_seen boolean NOT NULL,
    private_post_id bigint
);


--
-- Name: chat_message_custom_hashtags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_message_custom_hashtags (
    id bigint NOT NULL,
    message_id bigint,
    hashtag_id bigint,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: chat_message_custom_hashtags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_message_custom_hashtags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_message_custom_hashtags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_message_custom_hashtags_id_seq OWNED BY public.chat_message_custom_hashtags.id;


--
-- Name: chat_message_hashtags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_message_hashtags (
    id integer NOT NULL,
    message_id integer NOT NULL,
    interest_id integer NOT NULL
);


--
-- Name: chat_message_hashtags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_message_hashtags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_message_hashtags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_message_hashtags_id_seq OWNED BY public.chat_message_hashtags.id;


--
-- Name: chat_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_message_id_seq OWNED BY public.chat_message.id;


--
-- Name: chat_message_users_seen_message; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_message_users_seen_message (
    id integer NOT NULL,
    message_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: chat_message_users_seen_message_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_message_users_seen_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_message_users_seen_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_message_users_seen_message_id_seq OWNED BY public.chat_message_users_seen_message.id;


--
-- Name: chat_message_usertags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_message_usertags (
    id integer NOT NULL,
    message_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: chat_message_usertags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_message_usertags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_message_usertags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_message_usertags_id_seq OWNED BY public.chat_message_usertags.id;


--
-- Name: chat_room; Type: TABLE; Schema: public; Owner: -
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
    place_id bigint,
    safe_location public.geography(Point,4326),
    "popular_notified?" boolean DEFAULT false
);


--
-- Name: chat_room_administrators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_room_administrators (
    id integer NOT NULL,
    room_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: chat_room_administrators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_room_administrators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_room_administrators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_room_administrators_id_seq OWNED BY public.chat_room_administrators.id;


--
-- Name: chat_room_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_room_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_room_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_room_id_seq OWNED BY public.chat_room.id;


--
-- Name: chat_room_interests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_room_interests (
    id integer NOT NULL,
    room_id integer NOT NULL,
    interest_id integer NOT NULL
);


--
-- Name: chat_room_interests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_room_interests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_room_interests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_room_interests_id_seq OWNED BY public.chat_room_interests.id;


--
-- Name: chat_room_pending; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_room_pending (
    id integer NOT NULL,
    room_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: chat_room_pending_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_room_pending_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_room_pending_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_room_pending_id_seq OWNED BY public.chat_room_pending.id;


--
-- Name: chat_room_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_room_users (
    id integer NOT NULL,
    room_id integer NOT NULL,
    userprofile_id integer NOT NULL,
    "muted?" boolean DEFAULT false
);


--
-- Name: chat_room_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_room_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_room_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_room_users_id_seq OWNED BY public.chat_room_users.id;


--
-- Name: comment_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comment_uploads (
    comment_id bigint NOT NULL,
    upload_key character varying(255) NOT NULL
);


--
-- Name: comments_comments; Type: TABLE; Schema: public; Owner: -
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
    parent_id bigint
);


--
-- Name: comments_comments_downvotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments_comments_downvotes (
    id integer NOT NULL,
    comments_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: comments_comments_downvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_comments_downvotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_comments_downvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_comments_downvotes_id_seq OWNED BY public.comments_comments_downvotes.id;


--
-- Name: comments_comments_hashtags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments_comments_hashtags (
    id integer NOT NULL,
    comments_id integer NOT NULL,
    interest_id integer NOT NULL
);


--
-- Name: comments_comments_hashtags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_comments_hashtags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_comments_hashtags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_comments_hashtags_id_seq OWNED BY public.comments_comments_hashtags.id;


--
-- Name: comments_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_comments_id_seq OWNED BY public.comments_comments.id;


--
-- Name: comments_comments_upvotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments_comments_upvotes (
    id integer NOT NULL,
    comments_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: comments_comments_upvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_comments_upvotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_comments_upvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_comments_upvotes_id_seq OWNED BY public.comments_comments_upvotes.id;


--
-- Name: comments_comments_usertags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments_comments_usertags (
    id integer NOT NULL,
    comments_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: comments_comments_usertags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_comments_usertags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_comments_usertags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_comments_usertags_id_seq OWNED BY public.comments_comments_usertags.id;


--
-- Name: custom_hashtags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_hashtags (
    id bigint NOT NULL,
    value character varying(255),
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: custom_hashtags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_hashtags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_hashtags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_hashtags_id_seq OWNED BY public.custom_hashtags.id;


--
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.django_admin_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.django_admin_log_id_seq OWNED BY public.django_admin_log.id;


--
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.django_content_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: django_content_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.django_content_type_id_seq OWNED BY public.django_content_type.id;


--
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_migrations (
    id integer NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: django_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.django_migrations_id_seq OWNED BY public.django_migrations.id;


--
-- Name: django_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


--
-- Name: django_site; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_site (
    id integer NOT NULL,
    domain character varying(100) NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: django_site_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.django_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: django_site_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.django_site_id_seq OWNED BY public.django_site.id;


--
-- Name: dropchat_elevated_privileges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dropchat_elevated_privileges (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    dropchat_id bigint NOT NULL,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: dropchat_elevated_privileges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dropchat_elevated_privileges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dropchat_elevated_privileges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dropchat_elevated_privileges_id_seq OWNED BY public.dropchat_elevated_privileges.id;


--
-- Name: event_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_uploads (
    event_id bigint NOT NULL,
    upload_key character varying(255) NOT NULL
);


--
-- Name: eventbrite_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventbrite_requests (
    datetime timestamp without time zone NOT NULL,
    location public.geography(Point,4326) NOT NULL,
    radius integer
);


--
-- Name: eventful_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventful_events (
    id character varying(255) NOT NULL,
    data jsonb NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: eventful_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventful_requests (
    datetime timestamp without time zone NOT NULL,
    location public.geography(Point,4326) NOT NULL,
    radius integer
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id bigint NOT NULL,
    post_id bigint NOT NULL,
    location public.geography(Point,4326) NOT NULL,
    title character varying(255) NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    body text,
    price double precision,
    currency character varying(40),
    buy_ticket_link character varying(512),
    begin_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone,
    child_friendly boolean DEFAULT false,
    place_id bigint,
    tsvector tsvector,
    categories character varying(255)[] DEFAULT ARRAY[]::character varying[],
    eventbrite_id bigint,
    eventbrite_urls character varying(255)[],
    eventful_id character varying(255),
    eventful_urls character varying(255)[]
);


--
-- Name: events_attendees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_attendees (
    id bigint NOT NULL,
    event_id bigint NOT NULL,
    user_id bigint NOT NULL,
    status character varying(10),
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: events_attendees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_attendees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_attendees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_attendees_id_seq OWNED BY public.events_attendees.id;


--
-- Name: interests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interests (
    id bigint NOT NULL,
    hashtag character varying(255) NOT NULL,
    "disabled?" boolean DEFAULT false,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: interests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.interests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: interests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.interests_id_seq OWNED BY public.interests.id;


--
-- Name: interests_interest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interests_interest (
    id integer NOT NULL,
    name character varying(25) NOT NULL,
    hashtag character varying(25) NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    "isDisabled" boolean NOT NULL
);


--
-- Name: interests_interest_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.interests_interest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: interests_interest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.interests_interest_id_seq OWNED BY public.interests_interest.id;


--
-- Name: interests_userinterest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interests_userinterest (
    id integer NOT NULL,
    rating smallint NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    interest_id bigint NOT NULL,
    user_id integer NOT NULL,
    CONSTRAINT interests_userinterest_rating_check CHECK ((rating >= 0))
);


--
-- Name: interests_userinterest_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.interests_userinterest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: interests_userinterest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.interests_userinterest_id_seq OWNED BY public.interests_userinterest.id;


--
-- Name: livestream_comment_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.livestream_comment_votes (
    comment_id bigint NOT NULL,
    user_id bigint NOT NULL,
    vote_type character varying(255) NOT NULL,
    created timestamp(0) without time zone NOT NULL,
    updated timestamp(0) without time zone NOT NULL
);


--
-- Name: livestream_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.livestream_comments (
    id bigint NOT NULL,
    body text NOT NULL,
    author_id bigint NOT NULL,
    livestream_id uuid NOT NULL,
    created timestamp(0) without time zone NOT NULL,
    updated timestamp(0) without time zone NOT NULL
);


--
-- Name: livestream_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.livestream_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: livestream_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.livestream_comments_id_seq OWNED BY public.livestream_comments.id;


--
-- Name: livestream_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.livestream_views (
    livestream_id uuid NOT NULL,
    user_id bigint NOT NULL,
    created timestamp(0) without time zone NOT NULL,
    updated timestamp(0) without time zone NOT NULL
);


--
-- Name: livestream_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.livestream_votes (
    livestream_id uuid NOT NULL,
    user_id bigint NOT NULL,
    vote_type character varying(255) NOT NULL,
    created timestamp(0) without time zone NOT NULL,
    updated timestamp(0) without time zone NOT NULL
);


--
-- Name: livestreams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.livestreams (
    id uuid NOT NULL,
    title character varying(255) NOT NULL,
    owner_id bigint NOT NULL,
    ended_at timestamp without time zone,
    "active?" boolean DEFAULT false NOT NULL,
    "recorded?" boolean DEFAULT false NOT NULL,
    created timestamp(0) without time zone NOT NULL,
    updated timestamp(0) without time zone NOT NULL,
    location public.geography(Point,4326)
);


--
-- Name: message_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_uploads (
    message_id bigint NOT NULL,
    upload_key character varying(255) NOT NULL
);


--
-- Name: notifications_notification; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_notification_id_seq OWNED BY public.notifications_notification.id;


--
-- Name: places; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.places (
    id bigint NOT NULL,
    name character varying(512) NOT NULL,
    place_id character varying(512) NOT NULL,
    address character varying(512) NOT NULL,
    icon character varying(2048),
    vicinity character varying(512) DEFAULT ''::character varying,
    location public.geography(Point,4326) NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    source character varying(32) DEFAULT 'google maps'::character varying
);


--
-- Name: places_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.places_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: places_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.places_id_seq OWNED BY public.places.id;


--
-- Name: places_placetype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.places_placetype (
    id integer NOT NULL,
    name character varying(64) NOT NULL
);


--
-- Name: places_placetype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.places_placetype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: places_placetype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.places_placetype_id_seq OWNED BY public.places_placetype.id;


--
-- Name: places_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.places_types (
    id bigint NOT NULL,
    name text NOT NULL
);


--
-- Name: places_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.places_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: places_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.places_types_id_seq OWNED BY public.places_types.id;


--
-- Name: places_typeship; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.places_typeship (
    id bigint NOT NULL,
    place_id bigint,
    type_id bigint
);


--
-- Name: places_typeship_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.places_typeship_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: places_typeship_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.places_typeship_id_seq OWNED BY public.places_typeship.id;


--
-- Name: poll; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.poll (
    id bigint NOT NULL,
    question text NOT NULL,
    post_id bigint,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: poll_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.poll_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poll_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.poll_id_seq OWNED BY public.poll.id;


--
-- Name: poll_item_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.poll_item_uploads (
    poll_item_id bigint NOT NULL,
    upload_key character varying(255) NOT NULL
);


--
-- Name: poll_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.poll_items (
    id bigint NOT NULL,
    title character varying(512) NOT NULL,
    media_file_keys character varying(255)[] DEFAULT ARRAY[]::character varying[],
    poll_id bigint
);


--
-- Name: poll_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.poll_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poll_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.poll_items_id_seq OWNED BY public.poll_items.id;


--
-- Name: polls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.polls (
    id bigint NOT NULL,
    question text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tsvector tsvector,
    post_id bigint NOT NULL
);


--
-- Name: polls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.polls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.polls_id_seq OWNED BY public.polls.id;


--
-- Name: polls_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.polls_items (
    id bigint NOT NULL,
    title character varying(512) NOT NULL,
    poll_id bigint
);


--
-- Name: polls_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.polls_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polls_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.polls_items_id_seq OWNED BY public.polls_items.id;


--
-- Name: polls_items_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.polls_items_votes (
    id bigint NOT NULL,
    poll_item_id bigint NOT NULL,
    user_id bigint NOT NULL,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: polls_items_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.polls_items_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polls_items_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.polls_items_votes_id_seq OWNED BY public.polls_items_votes.id;


--
-- Name: post_approval_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_approval_request (
    post_id bigint NOT NULL,
    approver_id bigint NOT NULL,
    requester_id bigint NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: post_approval_request_rejection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_approval_request_rejection (
    post_id bigint NOT NULL,
    approver_id bigint NOT NULL,
    requester_id bigint NOT NULL,
    note text,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: post_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_uploads (
    post_id bigint NOT NULL,
    upload_key character varying(255) NOT NULL
);


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id bigint NOT NULL,
    type character varying(10) NOT NULL,
    author_id bigint NOT NULL,
    title character varying(512),
    body text,
    location public.geography(Point,4326) NOT NULL,
    fake_location public.geography(Point,4326),
    parent_id bigint,
    place_id bigint,
    post_cost integer,
    "private?" boolean DEFAULT false,
    business_admin_id bigint,
    business_id bigint,
    business_name character varying(255),
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tsvector tsvector,
    "approved?" boolean DEFAULT true,
    "popular_notified?" boolean DEFAULT false,
    eventbrite_id bigint,
    eventbrite_urls character varying(255)[],
    eventful_id character varying(255),
    eventful_urls character varying(255)[]
);


--
-- Name: posts_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts_comments (
    id bigint NOT NULL,
    post_id bigint NOT NULL,
    author_id bigint NOT NULL,
    body text DEFAULT ''::text NOT NULL,
    "disabled?" boolean DEFAULT false,
    parent_id bigint,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tsvector tsvector
);


--
-- Name: posts_comments_downvotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts_comments_downvotes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    comment_id bigint NOT NULL,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: posts_comments_downvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_comments_downvotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_comments_downvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_comments_downvotes_id_seq OWNED BY public.posts_comments_downvotes.id;


--
-- Name: posts_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_comments_id_seq OWNED BY public.posts_comments.id;


--
-- Name: posts_comments_interests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts_comments_interests (
    id bigint NOT NULL,
    comment_id bigint NOT NULL,
    interest_id bigint NOT NULL
);


--
-- Name: posts_comments_interests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_comments_interests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_comments_interests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_comments_interests_id_seq OWNED BY public.posts_comments_interests.id;


--
-- Name: posts_comments_upvotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts_comments_upvotes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    comment_id bigint NOT NULL,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: posts_comments_upvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_comments_upvotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_comments_upvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_comments_upvotes_id_seq OWNED BY public.posts_comments_upvotes.id;


--
-- Name: posts_downvotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts_downvotes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    post_id bigint NOT NULL,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: posts_downvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_downvotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_downvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_downvotes_id_seq OWNED BY public.posts_downvotes.id;


--
-- Name: posts_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_events_id_seq OWNED BY public.events.id;


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: posts_interests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts_interests (
    id bigint NOT NULL,
    post_id bigint NOT NULL,
    interest_id bigint NOT NULL
);


--
-- Name: posts_interests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_interests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_interests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_interests_id_seq OWNED BY public.posts_interests.id;


--
-- Name: posts_upvotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts_upvotes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    post_id bigint NOT NULL,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: posts_upvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_upvotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_upvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_upvotes_id_seq OWNED BY public.posts_upvotes.id;


--
-- Name: pst_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_event (
    post_ptr_id integer NOT NULL,
    date timestamp with time zone NOT NULL,
    event_location public.geography(Point,4326) NOT NULL
);


--
-- Name: pst_event_attendees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_event_attendees (
    id integer NOT NULL,
    event_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: pst_event_attendees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pst_event_attendees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pst_event_attendees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pst_event_attendees_id_seq OWNED BY public.pst_event_attendees.id;


--
-- Name: pst_poll; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_poll (
    post_ptr_id integer NOT NULL
);


--
-- Name: pst_pollitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_pollitem (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    poll_id integer NOT NULL,
    media_file_keys character varying(36)[] NOT NULL
);


--
-- Name: pst_pollitem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pst_pollitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pst_pollitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pst_pollitem_id_seq OWNED BY public.pst_pollitem.id;


--
-- Name: pst_pollitem_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_pollitem_votes (
    id integer NOT NULL,
    pollitem_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: pst_pollitem_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pst_pollitem_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pst_pollitem_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pst_pollitem_votes_id_seq OWNED BY public.pst_pollitem_votes.id;


--
-- Name: pst_post; Type: TABLE; Schema: public; Owner: -
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
    place_id bigint,
    media_file_keys character varying(36)[] NOT NULL,
    post_type character varying(10) NOT NULL,
    tsv tsvector,
    is_hide boolean DEFAULT false NOT NULL,
    is_business boolean DEFAULT false NOT NULL,
    business_account_id integer,
    business_username character varying(255),
    admin_username character varying(255),
    business_admin_id bigint
);


--
-- Name: pst_post_downvotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_post_downvotes (
    id integer NOT NULL,
    post_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: pst_post_downvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pst_post_downvotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pst_post_downvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pst_post_downvotes_id_seq OWNED BY public.pst_post_downvotes.id;


--
-- Name: pst_post_hashtags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_post_hashtags (
    id integer NOT NULL,
    post_id integer NOT NULL,
    interest_id integer NOT NULL
);


--
-- Name: pst_post_hashtags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pst_post_hashtags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pst_post_hashtags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pst_post_hashtags_id_seq OWNED BY public.pst_post_hashtags.id;


--
-- Name: pst_post_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pst_post_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pst_post_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pst_post_id_seq OWNED BY public.pst_post.id;


--
-- Name: pst_post_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_post_report (
    id bigint NOT NULL,
    post_id bigint NOT NULL,
    reporter_id bigint NOT NULL,
    reason_id bigint NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL
);


--
-- Name: pst_post_report_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pst_post_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pst_post_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pst_post_report_id_seq OWNED BY public.pst_post_report.id;


--
-- Name: pst_post_report_reason; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_post_report_reason (
    id bigint NOT NULL,
    report_reason character varying(255) NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL
);


--
-- Name: pst_post_report_reason_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pst_post_report_reason_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pst_post_report_reason_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pst_post_report_reason_id_seq OWNED BY public.pst_post_report_reason.id;


--
-- Name: pst_post_upvotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_post_upvotes (
    id integer NOT NULL,
    post_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: pst_post_upvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pst_post_upvotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pst_post_upvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pst_post_upvotes_id_seq OWNED BY public.pst_post_upvotes.id;


--
-- Name: pst_post_usertags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_post_usertags (
    id integer NOT NULL,
    post_id integer NOT NULL,
    userprofile_id integer NOT NULL
);


--
-- Name: pst_post_usertags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pst_post_usertags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pst_post_usertags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pst_post_usertags_id_seq OWNED BY public.pst_post_usertags.id;


--
-- Name: pst_votepost; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pst_votepost (
    post_ptr_id integer NOT NULL
);


--
-- Name: rihanna_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rihanna_jobs (
    id integer NOT NULL,
    term bytea NOT NULL,
    priority integer DEFAULT 50 NOT NULL,
    enqueued_at timestamp with time zone NOT NULL,
    due_at timestamp with time zone,
    failed_at timestamp with time zone,
    fail_reason text,
    rihanna_internal_meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT failed_at_required_fail_reason CHECK ((((failed_at IS NOT NULL) AND (fail_reason IS NOT NULL)) OR ((failed_at IS NULL) AND (fail_reason IS NULL))))
);


--
-- Name: CONSTRAINT failed_at_required_fail_reason ON rihanna_jobs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT failed_at_required_fail_reason ON public.rihanna_jobs IS 'When setting failed_at you must also set a fail_reason';


--
-- Name: rihanna_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rihanna_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1
    CYCLE;


--
-- Name: rihanna_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rihanna_jobs_id_seq OWNED BY public.rihanna_jobs.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: upload_fileupload; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.upload_fileupload (
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    owner_id integer NOT NULL,
    media character varying(100),
    media_type character varying(5) NOT NULL,
    media_key character varying(36) NOT NULL,
    media_thumbnail character varying(100)
);


--
-- Name: accounts_feedback id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_feedback ALTER COLUMN id SET DEFAULT nextval('public.accounts_feedback_id_seq'::regclass);


--
-- Name: accounts_invites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_invites ALTER COLUMN id SET DEFAULT nextval('public.accounts_invites_id_seq'::regclass);


--
-- Name: accounts_membership id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_membership ALTER COLUMN id SET DEFAULT nextval('public.accounts_membership_id_seq'::regclass);


--
-- Name: accounts_userprofile id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_id_seq'::regclass);


--
-- Name: accounts_userprofile_blocked id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_blocked ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_blocked_id_seq'::regclass);


--
-- Name: accounts_userprofile_close_friends id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_close_friends ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_close_friends_id_seq'::regclass);


--
-- Name: accounts_userprofile_follows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_follows ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_follows_id_seq'::regclass);


--
-- Name: accounts_userprofile_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_groups ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_groups_id_seq'::regclass);


--
-- Name: accounts_userprofile_user_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_user_permissions ALTER COLUMN id SET DEFAULT nextval('public.accounts_userprofile_user_permissions_id_seq'::regclass);


--
-- Name: actstream_action id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actstream_action ALTER COLUMN id SET DEFAULT nextval('public.actstream_action_id_seq'::regclass);


--
-- Name: actstream_follow id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actstream_follow ALTER COLUMN id SET DEFAULT nextval('public.actstream_follow_id_seq'::regclass);


--
-- Name: appnotifications_device id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appnotifications_device ALTER COLUMN id SET DEFAULT nextval('public.appnotifications_device_id_seq'::regclass);


--
-- Name: auth_group id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group ALTER COLUMN id SET DEFAULT nextval('public.auth_group_id_seq'::regclass);


--
-- Name: auth_group_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions ALTER COLUMN id SET DEFAULT nextval('public.auth_group_permissions_id_seq'::regclass);


--
-- Name: auth_permission id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission ALTER COLUMN id SET DEFAULT nextval('public.auth_permission_id_seq'::regclass);


--
-- Name: business_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_categories ALTER COLUMN id SET DEFAULT nextval('public.business_categories_id_seq'::regclass);


--
-- Name: businesses_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.businesses_categories ALTER COLUMN id SET DEFAULT nextval('public.businesses_categories_id_seq'::regclass);


--
-- Name: change_password id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.change_password ALTER COLUMN id SET DEFAULT nextval('public.change_password_id_seq'::regclass);


--
-- Name: chat_message id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message ALTER COLUMN id SET DEFAULT nextval('public.chat_message_id_seq'::regclass);


--
-- Name: chat_message_custom_hashtags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_custom_hashtags ALTER COLUMN id SET DEFAULT nextval('public.chat_message_custom_hashtags_id_seq'::regclass);


--
-- Name: chat_message_hashtags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_hashtags ALTER COLUMN id SET DEFAULT nextval('public.chat_message_hashtags_id_seq'::regclass);


--
-- Name: chat_message_users_seen_message id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_users_seen_message ALTER COLUMN id SET DEFAULT nextval('public.chat_message_users_seen_message_id_seq'::regclass);


--
-- Name: chat_message_usertags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_usertags ALTER COLUMN id SET DEFAULT nextval('public.chat_message_usertags_id_seq'::regclass);


--
-- Name: chat_room id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room ALTER COLUMN id SET DEFAULT nextval('public.chat_room_id_seq'::regclass);


--
-- Name: chat_room_administrators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_administrators ALTER COLUMN id SET DEFAULT nextval('public.chat_room_administrators_id_seq'::regclass);


--
-- Name: chat_room_interests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_interests ALTER COLUMN id SET DEFAULT nextval('public.chat_room_interests_id_seq'::regclass);


--
-- Name: chat_room_pending id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_pending ALTER COLUMN id SET DEFAULT nextval('public.chat_room_pending_id_seq'::regclass);


--
-- Name: chat_room_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_users ALTER COLUMN id SET DEFAULT nextval('public.chat_room_users_id_seq'::regclass);


--
-- Name: comments_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments ALTER COLUMN id SET DEFAULT nextval('public.comments_comments_id_seq'::regclass);


--
-- Name: comments_comments_downvotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_downvotes ALTER COLUMN id SET DEFAULT nextval('public.comments_comments_downvotes_id_seq'::regclass);


--
-- Name: comments_comments_hashtags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_hashtags ALTER COLUMN id SET DEFAULT nextval('public.comments_comments_hashtags_id_seq'::regclass);


--
-- Name: comments_comments_upvotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_upvotes ALTER COLUMN id SET DEFAULT nextval('public.comments_comments_upvotes_id_seq'::regclass);


--
-- Name: comments_comments_usertags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_usertags ALTER COLUMN id SET DEFAULT nextval('public.comments_comments_usertags_id_seq'::regclass);


--
-- Name: custom_hashtags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_hashtags ALTER COLUMN id SET DEFAULT nextval('public.custom_hashtags_id_seq'::regclass);


--
-- Name: django_admin_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log ALTER COLUMN id SET DEFAULT nextval('public.django_admin_log_id_seq'::regclass);


--
-- Name: django_content_type id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_content_type ALTER COLUMN id SET DEFAULT nextval('public.django_content_type_id_seq'::regclass);


--
-- Name: django_migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_migrations ALTER COLUMN id SET DEFAULT nextval('public.django_migrations_id_seq'::regclass);


--
-- Name: django_site id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_site ALTER COLUMN id SET DEFAULT nextval('public.django_site_id_seq'::regclass);


--
-- Name: dropchat_elevated_privileges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dropchat_elevated_privileges ALTER COLUMN id SET DEFAULT nextval('public.dropchat_elevated_privileges_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.posts_events_id_seq'::regclass);


--
-- Name: events_attendees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_attendees ALTER COLUMN id SET DEFAULT nextval('public.events_attendees_id_seq'::regclass);


--
-- Name: interests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests ALTER COLUMN id SET DEFAULT nextval('public.interests_id_seq'::regclass);


--
-- Name: interests_interest id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests_interest ALTER COLUMN id SET DEFAULT nextval('public.interests_interest_id_seq'::regclass);


--
-- Name: interests_userinterest id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests_userinterest ALTER COLUMN id SET DEFAULT nextval('public.interests_userinterest_id_seq'::regclass);


--
-- Name: livestream_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_comments ALTER COLUMN id SET DEFAULT nextval('public.livestream_comments_id_seq'::regclass);


--
-- Name: notifications_notification id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_notification ALTER COLUMN id SET DEFAULT nextval('public.notifications_notification_id_seq'::regclass);


--
-- Name: places id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places ALTER COLUMN id SET DEFAULT nextval('public.places_id_seq'::regclass);


--
-- Name: places_placetype id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places_placetype ALTER COLUMN id SET DEFAULT nextval('public.places_placetype_id_seq'::regclass);


--
-- Name: places_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places_types ALTER COLUMN id SET DEFAULT nextval('public.places_types_id_seq'::regclass);


--
-- Name: places_typeship id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places_typeship ALTER COLUMN id SET DEFAULT nextval('public.places_typeship_id_seq'::regclass);


--
-- Name: poll id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll ALTER COLUMN id SET DEFAULT nextval('public.poll_id_seq'::regclass);


--
-- Name: poll_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_items ALTER COLUMN id SET DEFAULT nextval('public.poll_items_id_seq'::regclass);


--
-- Name: polls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls ALTER COLUMN id SET DEFAULT nextval('public.polls_id_seq'::regclass);


--
-- Name: polls_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls_items ALTER COLUMN id SET DEFAULT nextval('public.polls_items_id_seq'::regclass);


--
-- Name: polls_items_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls_items_votes ALTER COLUMN id SET DEFAULT nextval('public.polls_items_votes_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: posts_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments ALTER COLUMN id SET DEFAULT nextval('public.posts_comments_id_seq'::regclass);


--
-- Name: posts_comments_downvotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_downvotes ALTER COLUMN id SET DEFAULT nextval('public.posts_comments_downvotes_id_seq'::regclass);


--
-- Name: posts_comments_interests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_interests ALTER COLUMN id SET DEFAULT nextval('public.posts_comments_interests_id_seq'::regclass);


--
-- Name: posts_comments_upvotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_upvotes ALTER COLUMN id SET DEFAULT nextval('public.posts_comments_upvotes_id_seq'::regclass);


--
-- Name: posts_downvotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_downvotes ALTER COLUMN id SET DEFAULT nextval('public.posts_downvotes_id_seq'::regclass);


--
-- Name: posts_interests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_interests ALTER COLUMN id SET DEFAULT nextval('public.posts_interests_id_seq'::regclass);


--
-- Name: posts_upvotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_upvotes ALTER COLUMN id SET DEFAULT nextval('public.posts_upvotes_id_seq'::regclass);


--
-- Name: pst_event_attendees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_event_attendees ALTER COLUMN id SET DEFAULT nextval('public.pst_event_attendees_id_seq'::regclass);


--
-- Name: pst_pollitem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_pollitem ALTER COLUMN id SET DEFAULT nextval('public.pst_pollitem_id_seq'::regclass);


--
-- Name: pst_pollitem_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_pollitem_votes ALTER COLUMN id SET DEFAULT nextval('public.pst_pollitem_votes_id_seq'::regclass);


--
-- Name: pst_post id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post ALTER COLUMN id SET DEFAULT nextval('public.pst_post_id_seq'::regclass);


--
-- Name: pst_post_downvotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_downvotes ALTER COLUMN id SET DEFAULT nextval('public.pst_post_downvotes_id_seq'::regclass);


--
-- Name: pst_post_hashtags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_hashtags ALTER COLUMN id SET DEFAULT nextval('public.pst_post_hashtags_id_seq'::regclass);


--
-- Name: pst_post_report id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_report ALTER COLUMN id SET DEFAULT nextval('public.pst_post_report_id_seq'::regclass);


--
-- Name: pst_post_report_reason id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_report_reason ALTER COLUMN id SET DEFAULT nextval('public.pst_post_report_reason_id_seq'::regclass);


--
-- Name: pst_post_upvotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_upvotes ALTER COLUMN id SET DEFAULT nextval('public.pst_post_upvotes_id_seq'::regclass);


--
-- Name: pst_post_usertags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_usertags ALTER COLUMN id SET DEFAULT nextval('public.pst_post_usertags_id_seq'::regclass);


--
-- Name: rihanna_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rihanna_jobs ALTER COLUMN id SET DEFAULT nextval('public.rihanna_jobs_id_seq'::regclass);


--
-- Name: accounts_feedback accounts_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_feedback
    ADD CONSTRAINT accounts_feedback_pkey PRIMARY KEY (id);


--
-- Name: accounts_invites accounts_invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_invites
    ADD CONSTRAINT accounts_invites_pkey PRIMARY KEY (id);


--
-- Name: accounts_membership accounts_membership_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_membership
    ADD CONSTRAINT accounts_membership_pkey PRIMARY KEY (id);


--
-- Name: accounts_userfeedback accounts_userfeedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userfeedback
    ADD CONSTRAINT accounts_userfeedback_pkey PRIMARY KEY (feedback_ptr_id);


--
-- Name: accounts_userprofile_blocked accounts_userprofile_blo_from_userprofile_id_to_u_2f6bb747_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_blocked
    ADD CONSTRAINT accounts_userprofile_blo_from_userprofile_id_to_u_2f6bb747_uniq UNIQUE (from_userprofile_id, to_userprofile_id);


--
-- Name: accounts_userprofile_blocked accounts_userprofile_blocked_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_blocked
    ADD CONSTRAINT accounts_userprofile_blocked_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile_close_friends accounts_userprofile_clo_from_userprofile_id_to_u_a9366b0c_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_close_friends
    ADD CONSTRAINT accounts_userprofile_clo_from_userprofile_id_to_u_a9366b0c_uniq UNIQUE (from_userprofile_id, to_userprofile_id);


--
-- Name: accounts_userprofile_close_friends accounts_userprofile_close_friends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_close_friends
    ADD CONSTRAINT accounts_userprofile_close_friends_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile_follows accounts_userprofile_fol_from_userprofile_id_to_u_96a4afdf_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_follows
    ADD CONSTRAINT accounts_userprofile_fol_from_userprofile_id_to_u_96a4afdf_uniq UNIQUE (from_userprofile_id, to_userprofile_id);


--
-- Name: accounts_userprofile_follows accounts_userprofile_follows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_follows
    ADD CONSTRAINT accounts_userprofile_follows_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile_groups accounts_userprofile_gro_userprofile_id_group_id_36cd9fa6_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_groups
    ADD CONSTRAINT accounts_userprofile_gro_userprofile_id_group_id_36cd9fa6_uniq UNIQUE (userprofile_id, group_id);


--
-- Name: accounts_userprofile_groups accounts_userprofile_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_groups
    ADD CONSTRAINT accounts_userprofile_groups_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile accounts_userprofile_phone_8e09b259_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile
    ADD CONSTRAINT accounts_userprofile_phone_8e09b259_uniq UNIQUE (phone);


--
-- Name: accounts_userprofile accounts_userprofile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile
    ADD CONSTRAINT accounts_userprofile_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile_user_permissions accounts_userprofile_use_userprofile_id_permissio_22053107_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_user_permissions
    ADD CONSTRAINT accounts_userprofile_use_userprofile_id_permissio_22053107_uniq UNIQUE (userprofile_id, permission_id);


--
-- Name: accounts_userprofile_user_permissions accounts_userprofile_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_user_permissions
    ADD CONSTRAINT accounts_userprofile_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: accounts_userprofile accounts_userprofile_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile
    ADD CONSTRAINT accounts_userprofile_username_key UNIQUE (username);


--
-- Name: actstream_action actstream_action_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actstream_action
    ADD CONSTRAINT actstream_action_pkey PRIMARY KEY (id);


--
-- Name: actstream_follow actstream_follow_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actstream_follow
    ADD CONSTRAINT actstream_follow_pkey PRIMARY KEY (id);


--
-- Name: actstream_follow actstream_follow_user_id_content_type_id__63ca7c27_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actstream_follow
    ADD CONSTRAINT actstream_follow_user_id_content_type_id__63ca7c27_uniq UNIQUE (user_id, content_type_id, object_id);


--
-- Name: appnotifications_device appnotifications_device_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appnotifications_device
    ADD CONSTRAINT appnotifications_device_pkey PRIMARY KEY (id);


--
-- Name: appnotifications_device appnotifications_device_token_6765efeb_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appnotifications_device
    ADD CONSTRAINT appnotifications_device_token_6765efeb_uniq UNIQUE (token);


--
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- Name: authtoken_token authtoken_token_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_pkey PRIMARY KEY (key);


--
-- Name: authtoken_token authtoken_token_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_user_id_key UNIQUE (user_id);


--
-- Name: business_categories business_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_categories
    ADD CONSTRAINT business_categories_pkey PRIMARY KEY (id);


--
-- Name: businesses_categories businesses_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.businesses_categories
    ADD CONSTRAINT businesses_categories_pkey PRIMARY KEY (id);


--
-- Name: change_password change_password_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.change_password
    ADD CONSTRAINT change_password_pkey PRIMARY KEY (id);


--
-- Name: chat_message_custom_hashtags chat_message_custom_hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_custom_hashtags
    ADD CONSTRAINT chat_message_custom_hashtags_pkey PRIMARY KEY (id);


--
-- Name: chat_message_hashtags chat_message_hashtags_message_id_interest_id_4a0b0eaa_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_hashtags
    ADD CONSTRAINT chat_message_hashtags_message_id_interest_id_4a0b0eaa_uniq UNIQUE (message_id, interest_id);


--
-- Name: chat_message_hashtags chat_message_hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_hashtags
    ADD CONSTRAINT chat_message_hashtags_pkey PRIMARY KEY (id);


--
-- Name: chat_message chat_message_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_pkey PRIMARY KEY (id);


--
-- Name: chat_message_users_seen_message chat_message_users_seen__message_id_userprofile_i_a58b508b_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_users_seen_message
    ADD CONSTRAINT chat_message_users_seen__message_id_userprofile_i_a58b508b_uniq UNIQUE (message_id, userprofile_id);


--
-- Name: chat_message_users_seen_message chat_message_users_seen_message_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_users_seen_message
    ADD CONSTRAINT chat_message_users_seen_message_pkey PRIMARY KEY (id);


--
-- Name: chat_message_usertags chat_message_usertags_message_id_userprofile_id_a51508ab_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_usertags
    ADD CONSTRAINT chat_message_usertags_message_id_userprofile_id_a51508ab_uniq UNIQUE (message_id, userprofile_id);


--
-- Name: chat_message_usertags chat_message_usertags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_usertags
    ADD CONSTRAINT chat_message_usertags_pkey PRIMARY KEY (id);


--
-- Name: chat_room_administrators chat_room_administrators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_administrators
    ADD CONSTRAINT chat_room_administrators_pkey PRIMARY KEY (id);


--
-- Name: chat_room_administrators chat_room_administrators_room_id_userprofile_id_5be12aef_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_administrators
    ADD CONSTRAINT chat_room_administrators_room_id_userprofile_id_5be12aef_uniq UNIQUE (room_id, userprofile_id);


--
-- Name: chat_room chat_room_interest_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room
    ADD CONSTRAINT chat_room_interest_id_key UNIQUE (interest_id);


--
-- Name: chat_room_interests chat_room_interests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_interests
    ADD CONSTRAINT chat_room_interests_pkey PRIMARY KEY (id);


--
-- Name: chat_room_interests chat_room_interests_room_id_interest_id_e3ed4a69_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_interests
    ADD CONSTRAINT chat_room_interests_room_id_interest_id_e3ed4a69_uniq UNIQUE (room_id, interest_id);


--
-- Name: chat_room chat_room_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room
    ADD CONSTRAINT chat_room_key_key UNIQUE (key);


--
-- Name: chat_room_pending chat_room_pending_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_pending
    ADD CONSTRAINT chat_room_pending_pkey PRIMARY KEY (id);


--
-- Name: chat_room_pending chat_room_pending_room_id_userprofile_id_165fd6e7_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_pending
    ADD CONSTRAINT chat_room_pending_room_id_userprofile_id_165fd6e7_uniq UNIQUE (room_id, userprofile_id);


--
-- Name: chat_room chat_room_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room
    ADD CONSTRAINT chat_room_pkey PRIMARY KEY (id);


--
-- Name: chat_room_users chat_room_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_users
    ADD CONSTRAINT chat_room_users_pkey PRIMARY KEY (id);


--
-- Name: chat_room_users chat_room_users_room_id_userprofile_id_d31d7c2f_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_users
    ADD CONSTRAINT chat_room_users_room_id_userprofile_id_d31d7c2f_uniq UNIQUE (room_id, userprofile_id);


--
-- Name: comment_uploads comment_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_uploads
    ADD CONSTRAINT comment_uploads_pkey PRIMARY KEY (comment_id, upload_key);


--
-- Name: comments_comments_downvotes comments_comments_downvo_comments_id_userprofile__7ac29cd9_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_downvotes
    ADD CONSTRAINT comments_comments_downvo_comments_id_userprofile__7ac29cd9_uniq UNIQUE (comments_id, userprofile_id);


--
-- Name: comments_comments_downvotes comments_comments_downvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_downvotes
    ADD CONSTRAINT comments_comments_downvotes_pkey PRIMARY KEY (id);


--
-- Name: comments_comments_hashtags comments_comments_hashta_comments_id_interest_id_dd18f3c9_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_hashtags
    ADD CONSTRAINT comments_comments_hashta_comments_id_interest_id_dd18f3c9_uniq UNIQUE (comments_id, interest_id);


--
-- Name: comments_comments_hashtags comments_comments_hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_hashtags
    ADD CONSTRAINT comments_comments_hashtags_pkey PRIMARY KEY (id);


--
-- Name: comments_comments comments_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments
    ADD CONSTRAINT comments_comments_pkey PRIMARY KEY (id);


--
-- Name: comments_comments_upvotes comments_comments_upvote_comments_id_userprofile__08971208_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_upvotes
    ADD CONSTRAINT comments_comments_upvote_comments_id_userprofile__08971208_uniq UNIQUE (comments_id, userprofile_id);


--
-- Name: comments_comments_upvotes comments_comments_upvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_upvotes
    ADD CONSTRAINT comments_comments_upvotes_pkey PRIMARY KEY (id);


--
-- Name: comments_comments_usertags comments_comments_userta_comments_id_userprofile__4181ee21_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_usertags
    ADD CONSTRAINT comments_comments_userta_comments_id_userprofile__4181ee21_uniq UNIQUE (comments_id, userprofile_id);


--
-- Name: comments_comments_usertags comments_comments_usertags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_usertags
    ADD CONSTRAINT comments_comments_usertags_pkey PRIMARY KEY (id);


--
-- Name: custom_hashtags custom_hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_hashtags
    ADD CONSTRAINT custom_hashtags_pkey PRIMARY KEY (id);


--
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- Name: django_site django_site_domain_a2e37b91_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_site
    ADD CONSTRAINT django_site_domain_a2e37b91_uniq UNIQUE (domain);


--
-- Name: django_site django_site_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_site
    ADD CONSTRAINT django_site_pkey PRIMARY KEY (id);


--
-- Name: dropchat_elevated_privileges dropchat_elevated_privileges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dropchat_elevated_privileges
    ADD CONSTRAINT dropchat_elevated_privileges_pkey PRIMARY KEY (id);


--
-- Name: event_uploads event_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_uploads
    ADD CONSTRAINT event_uploads_pkey PRIMARY KEY (event_id, upload_key);


--
-- Name: eventbrite_requests eventbrite_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventbrite_requests
    ADD CONSTRAINT eventbrite_requests_pkey PRIMARY KEY (datetime);


--
-- Name: eventful_events eventful_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventful_events
    ADD CONSTRAINT eventful_events_pkey PRIMARY KEY (id);


--
-- Name: eventful_requests eventful_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventful_requests
    ADD CONSTRAINT eventful_requests_pkey PRIMARY KEY (datetime);


--
-- Name: events_attendees events_attendees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_attendees
    ADD CONSTRAINT events_attendees_pkey PRIMARY KEY (id);


--
-- Name: interests_interest interests_interest_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests_interest
    ADD CONSTRAINT interests_interest_name_key UNIQUE (name);


--
-- Name: interests_interest interests_interest_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests_interest
    ADD CONSTRAINT interests_interest_pkey PRIMARY KEY (id);


--
-- Name: interests interests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests
    ADD CONSTRAINT interests_pkey PRIMARY KEY (id);


--
-- Name: interests_userinterest interests_userinterest_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests_userinterest
    ADD CONSTRAINT interests_userinterest_pkey PRIMARY KEY (id);


--
-- Name: interests_userinterest interests_userinterest_user_id_interest_id_744ff408_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests_userinterest
    ADD CONSTRAINT interests_userinterest_user_id_interest_id_744ff408_uniq UNIQUE (user_id, interest_id);


--
-- Name: livestream_comment_votes livestream_comment_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_comment_votes
    ADD CONSTRAINT livestream_comment_votes_pkey PRIMARY KEY (comment_id, user_id);


--
-- Name: livestream_comments livestream_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_comments
    ADD CONSTRAINT livestream_comments_pkey PRIMARY KEY (id);


--
-- Name: livestream_views livestream_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_views
    ADD CONSTRAINT livestream_views_pkey PRIMARY KEY (livestream_id, user_id);


--
-- Name: livestream_votes livestream_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_votes
    ADD CONSTRAINT livestream_votes_pkey PRIMARY KEY (livestream_id, user_id);


--
-- Name: livestreams livestreams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestreams
    ADD CONSTRAINT livestreams_pkey PRIMARY KEY (id);


--
-- Name: message_uploads message_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_uploads
    ADD CONSTRAINT message_uploads_pkey PRIMARY KEY (message_id, upload_key);


--
-- Name: notifications_notification notifications_notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notification_pkey PRIMARY KEY (id);


--
-- Name: places places_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places
    ADD CONSTRAINT places_pkey PRIMARY KEY (id);


--
-- Name: places_placetype places_placetype_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places_placetype
    ADD CONSTRAINT places_placetype_name_key UNIQUE (name);


--
-- Name: places_placetype places_placetype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places_placetype
    ADD CONSTRAINT places_placetype_pkey PRIMARY KEY (id);


--
-- Name: places_types places_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places_types
    ADD CONSTRAINT places_types_pkey PRIMARY KEY (id);


--
-- Name: places_typeship places_typeship_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places_typeship
    ADD CONSTRAINT places_typeship_pkey PRIMARY KEY (id);


--
-- Name: poll_item_uploads poll_item_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_item_uploads
    ADD CONSTRAINT poll_item_uploads_pkey PRIMARY KEY (poll_item_id, upload_key);


--
-- Name: poll_items poll_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_items
    ADD CONSTRAINT poll_items_pkey PRIMARY KEY (id);


--
-- Name: poll poll_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll
    ADD CONSTRAINT poll_pkey PRIMARY KEY (id);


--
-- Name: polls_items polls_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls_items
    ADD CONSTRAINT polls_items_pkey PRIMARY KEY (id);


--
-- Name: polls_items_votes polls_items_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls_items_votes
    ADD CONSTRAINT polls_items_votes_pkey PRIMARY KEY (id);


--
-- Name: polls polls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (id);


--
-- Name: post_approval_request post_approval_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_approval_request
    ADD CONSTRAINT post_approval_request_pkey PRIMARY KEY (post_id, approver_id, requester_id);


--
-- Name: post_approval_request_rejection post_approval_request_rejection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_approval_request_rejection
    ADD CONSTRAINT post_approval_request_rejection_pkey PRIMARY KEY (post_id, approver_id, requester_id);


--
-- Name: post_uploads post_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_uploads
    ADD CONSTRAINT post_uploads_pkey PRIMARY KEY (post_id, upload_key);


--
-- Name: posts_comments_downvotes posts_comments_downvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_downvotes
    ADD CONSTRAINT posts_comments_downvotes_pkey PRIMARY KEY (id);


--
-- Name: posts_comments_interests posts_comments_interests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_interests
    ADD CONSTRAINT posts_comments_interests_pkey PRIMARY KEY (id);


--
-- Name: posts_comments posts_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments
    ADD CONSTRAINT posts_comments_pkey PRIMARY KEY (id);


--
-- Name: posts_comments_upvotes posts_comments_upvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_upvotes
    ADD CONSTRAINT posts_comments_upvotes_pkey PRIMARY KEY (id);


--
-- Name: posts_downvotes posts_downvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_downvotes
    ADD CONSTRAINT posts_downvotes_pkey PRIMARY KEY (id);


--
-- Name: events posts_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT posts_events_pkey PRIMARY KEY (id);


--
-- Name: posts_interests posts_interests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_interests
    ADD CONSTRAINT posts_interests_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: posts_upvotes posts_upvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_upvotes
    ADD CONSTRAINT posts_upvotes_pkey PRIMARY KEY (id);


--
-- Name: pst_event_attendees pst_event_attendees_event_id_userprofile_id_175ca335_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_event_attendees
    ADD CONSTRAINT pst_event_attendees_event_id_userprofile_id_175ca335_uniq UNIQUE (event_id, userprofile_id);


--
-- Name: pst_event_attendees pst_event_attendees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_event_attendees
    ADD CONSTRAINT pst_event_attendees_pkey PRIMARY KEY (id);


--
-- Name: pst_event pst_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_event
    ADD CONSTRAINT pst_event_pkey PRIMARY KEY (post_ptr_id);


--
-- Name: pst_poll pst_poll_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_poll
    ADD CONSTRAINT pst_poll_pkey PRIMARY KEY (post_ptr_id);


--
-- Name: pst_pollitem pst_pollitem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_pollitem
    ADD CONSTRAINT pst_pollitem_pkey PRIMARY KEY (id);


--
-- Name: pst_pollitem_votes pst_pollitem_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_pollitem_votes
    ADD CONSTRAINT pst_pollitem_votes_pkey PRIMARY KEY (id);


--
-- Name: pst_pollitem_votes pst_pollitem_votes_pollitem_id_userprofile_id_ee2a092e_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_pollitem_votes
    ADD CONSTRAINT pst_pollitem_votes_pollitem_id_userprofile_id_ee2a092e_uniq UNIQUE (pollitem_id, userprofile_id);


--
-- Name: pst_post_downvotes pst_post_downvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_downvotes
    ADD CONSTRAINT pst_post_downvotes_pkey PRIMARY KEY (id);


--
-- Name: pst_post_downvotes pst_post_downvotes_post_id_userprofile_id_23396829_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_downvotes
    ADD CONSTRAINT pst_post_downvotes_post_id_userprofile_id_23396829_uniq UNIQUE (post_id, userprofile_id);


--
-- Name: pst_post_hashtags pst_post_hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_hashtags
    ADD CONSTRAINT pst_post_hashtags_pkey PRIMARY KEY (id);


--
-- Name: pst_post_hashtags pst_post_hashtags_post_id_interest_id_27f024ef_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_hashtags
    ADD CONSTRAINT pst_post_hashtags_post_id_interest_id_27f024ef_uniq UNIQUE (post_id, interest_id);


--
-- Name: pst_post pst_post_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post
    ADD CONSTRAINT pst_post_pkey PRIMARY KEY (id);


--
-- Name: pst_post_report pst_post_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_report
    ADD CONSTRAINT pst_post_report_pkey PRIMARY KEY (id);


--
-- Name: pst_post_report_reason pst_post_report_reason_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_report_reason
    ADD CONSTRAINT pst_post_report_reason_pkey PRIMARY KEY (id);


--
-- Name: pst_post_upvotes pst_post_upvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_upvotes
    ADD CONSTRAINT pst_post_upvotes_pkey PRIMARY KEY (id);


--
-- Name: pst_post_upvotes pst_post_upvotes_post_id_userprofile_id_93b46ae9_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_upvotes
    ADD CONSTRAINT pst_post_upvotes_post_id_userprofile_id_93b46ae9_uniq UNIQUE (post_id, userprofile_id);


--
-- Name: pst_post_usertags pst_post_usertags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_usertags
    ADD CONSTRAINT pst_post_usertags_pkey PRIMARY KEY (id);


--
-- Name: pst_post_usertags pst_post_usertags_post_id_userprofile_id_3a894e13_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_usertags
    ADD CONSTRAINT pst_post_usertags_post_id_userprofile_id_3a894e13_uniq UNIQUE (post_id, userprofile_id);


--
-- Name: pst_votepost pst_votepost_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_votepost
    ADD CONSTRAINT pst_votepost_pkey PRIMARY KEY (post_ptr_id);


--
-- Name: rihanna_jobs rihanna_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rihanna_jobs
    ADD CONSTRAINT rihanna_jobs_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: upload_fileupload upload_fileupload_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.upload_fileupload
    ADD CONSTRAINT upload_fileupload_pkey PRIMARY KEY (media_key);


--
-- Name: accounts_fe_created_75d4b9_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_fe_created_75d4b9_brin ON public.accounts_feedback USING brin (created);


--
-- Name: accounts_feedback_updated_2948a09e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_feedback_updated_2948a09e ON public.accounts_feedback USING btree (updated);


--
-- Name: accounts_in_created_94cfe9_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_in_created_94cfe9_brin ON public.accounts_invites USING brin (created);


--
-- Name: accounts_invites_user_id_f8798e32; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_invites_user_id_f8798e32 ON public.accounts_invites USING btree (user_id);


--
-- Name: accounts_membership_business_account_id_member_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts_membership_business_account_id_member_id_index ON public.accounts_membership USING btree (business_account_id, member_id);


--
-- Name: accounts_userfeedback_user_id_00952b3e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userfeedback_user_id_00952b3e ON public.accounts_userfeedback USING btree (user_id);


--
-- Name: accounts_userprofile_blocked_from_userprofile_id_355dc595; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_blocked_from_userprofile_id_355dc595 ON public.accounts_userprofile_blocked USING btree (from_userprofile_id);


--
-- Name: accounts_userprofile_blocked_to_userprofile_id_53778445; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_blocked_to_userprofile_id_53778445 ON public.accounts_userprofile_blocked USING btree (to_userprofile_id);


--
-- Name: accounts_userprofile_close_friends_from_userprofile_id_f1393c0b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_close_friends_from_userprofile_id_f1393c0b ON public.accounts_userprofile_close_friends USING btree (from_userprofile_id);


--
-- Name: accounts_userprofile_close_friends_to_userprofile_id_f0a3b464; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_close_friends_to_userprofile_id_f0a3b464 ON public.accounts_userprofile_close_friends USING btree (to_userprofile_id);


--
-- Name: accounts_userprofile_eventbrite_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts_userprofile_eventbrite_id_index ON public.accounts_userprofile USING btree (eventbrite_id);


--
-- Name: accounts_userprofile_eventful_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts_userprofile_eventful_id_index ON public.accounts_userprofile USING btree (eventful_id);


--
-- Name: accounts_userprofile_follows_from_userprofile_id_2798b703; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_follows_from_userprofile_id_2798b703 ON public.accounts_userprofile_follows USING btree (from_userprofile_id);


--
-- Name: accounts_userprofile_follows_to_userprofile_id_c73d9228; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_follows_to_userprofile_id_c73d9228 ON public.accounts_userprofile_follows USING btree (to_userprofile_id);


--
-- Name: accounts_userprofile_groups_group_id_74ae51cf; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_groups_group_id_74ae51cf ON public.accounts_userprofile_groups USING btree (group_id);


--
-- Name: accounts_userprofile_groups_userprofile_id_b7fb6469; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_groups_userprofile_id_b7fb6469 ON public.accounts_userprofile_groups USING btree (userprofile_id);


--
-- Name: accounts_userprofile_phone_8e09b259_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_phone_8e09b259_like ON public.accounts_userprofile USING btree (phone varchar_pattern_ops);


--
-- Name: accounts_userprofile_user_permissions_permission_id_a9b2b32b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_user_permissions_permission_id_a9b2b32b ON public.accounts_userprofile_user_permissions USING btree (permission_id);


--
-- Name: accounts_userprofile_user_permissions_userprofile_id_4acaf5a0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_user_permissions_userprofile_id_4acaf5a0 ON public.accounts_userprofile_user_permissions USING btree (userprofile_id);


--
-- Name: accounts_userprofile_user_real_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_user_real_location_id ON public.accounts_userprofile USING gist (user_real_location);


--
-- Name: accounts_userprofile_user_safe_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_user_safe_location_id ON public.accounts_userprofile USING gist (user_safe_location);


--
-- Name: accounts_userprofile_username_8e8bc851_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_username_8e8bc851_like ON public.accounts_userprofile USING btree (username varchar_pattern_ops);


--
-- Name: accounts_userprofile_username_trgm_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts_userprofile_username_trgm_index ON public.accounts_userprofile USING gin (username public.gin_trgm_ops);


--
-- Name: actstream_action_action_object_content_type_id_ee623c15; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_action_object_content_type_id_ee623c15 ON public.actstream_action USING btree (action_object_content_type_id);


--
-- Name: actstream_action_action_object_object_id_6433bdf7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_action_object_object_id_6433bdf7 ON public.actstream_action USING btree (action_object_object_id);


--
-- Name: actstream_action_action_object_object_id_6433bdf7_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_action_object_object_id_6433bdf7_like ON public.actstream_action USING btree (action_object_object_id varchar_pattern_ops);


--
-- Name: actstream_action_actor_content_type_id_d5e5ec2a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_actor_content_type_id_d5e5ec2a ON public.actstream_action USING btree (actor_content_type_id);


--
-- Name: actstream_action_actor_object_id_72ef0cfa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_actor_object_id_72ef0cfa ON public.actstream_action USING btree (actor_object_id);


--
-- Name: actstream_action_actor_object_id_72ef0cfa_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_actor_object_id_72ef0cfa_like ON public.actstream_action USING btree (actor_object_id varchar_pattern_ops);


--
-- Name: actstream_action_public_ac0653e9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_public_ac0653e9 ON public.actstream_action USING btree (public);


--
-- Name: actstream_action_target_content_type_id_187fa164; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_target_content_type_id_187fa164 ON public.actstream_action USING btree (target_content_type_id);


--
-- Name: actstream_action_target_object_id_e080d801; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_target_object_id_e080d801 ON public.actstream_action USING btree (target_object_id);


--
-- Name: actstream_action_target_object_id_e080d801_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_target_object_id_e080d801_like ON public.actstream_action USING btree (target_object_id varchar_pattern_ops);


--
-- Name: actstream_action_timestamp_a23fe3ae; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_timestamp_a23fe3ae ON public.actstream_action USING btree ("timestamp");


--
-- Name: actstream_action_verb_83f768b7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_verb_83f768b7 ON public.actstream_action USING btree (verb);


--
-- Name: actstream_action_verb_83f768b7_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_action_verb_83f768b7_like ON public.actstream_action USING btree (verb varchar_pattern_ops);


--
-- Name: actstream_follow_content_type_id_ba287eb9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_follow_content_type_id_ba287eb9 ON public.actstream_follow USING btree (content_type_id);


--
-- Name: actstream_follow_object_id_d790e00d; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_follow_object_id_d790e00d ON public.actstream_follow USING btree (object_id);


--
-- Name: actstream_follow_object_id_d790e00d_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_follow_object_id_d790e00d_like ON public.actstream_follow USING btree (object_id varchar_pattern_ops);


--
-- Name: actstream_follow_started_254c63bd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_follow_started_254c63bd ON public.actstream_follow USING btree (started);


--
-- Name: actstream_follow_user_id_e9d4e1ff; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX actstream_follow_user_id_e9d4e1ff ON public.actstream_follow USING btree (user_id);


--
-- Name: appnotifica_created_98e6fb_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appnotifica_created_98e6fb_brin ON public.appnotifications_device USING brin (created);


--
-- Name: appnotifications_device_token_6765efeb_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appnotifications_device_token_6765efeb_like ON public.appnotifications_device USING btree (token varchar_pattern_ops);


--
-- Name: appnotifications_device_updated_f0473e4e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appnotifications_device_updated_f0473e4e ON public.appnotifications_device USING btree (updated);


--
-- Name: appnotifications_device_user_id_e281be8a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appnotifications_device_user_id_e281be8a ON public.appnotifications_device USING btree (user_id);


--
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- Name: authtoken_token_key_10f0b77e_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX authtoken_token_key_10f0b77e_like ON public.authtoken_token USING btree (key varchar_pattern_ops);


--
-- Name: change_password_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX change_password_user_id_index ON public.change_password USING btree (user_id);


--
-- Name: chat_messag_created_aeee25_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_messag_created_aeee25_brin ON public.chat_message USING brin (created);


--
-- Name: chat_message_custom_hashtags_hashtag_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_custom_hashtags_hashtag_id_index ON public.chat_message_custom_hashtags USING btree (hashtag_id);


--
-- Name: chat_message_custom_hashtags_message_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_custom_hashtags_message_id_index ON public.chat_message_custom_hashtags USING btree (message_id);


--
-- Name: chat_message_forwarded_message_id_3a06f552; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_forwarded_message_id_3a06f552 ON public.chat_message USING btree (forwarded_message_id);


--
-- Name: chat_message_hashtags_interest_id_3116b459; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_hashtags_interest_id_3116b459 ON public.chat_message_hashtags USING btree (interest_id);


--
-- Name: chat_message_hashtags_message_id_80415300; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_hashtags_message_id_80415300 ON public.chat_message_hashtags USING btree (message_id);


--
-- Name: chat_message_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_location_id ON public.chat_message USING gist (location);


--
-- Name: chat_message_parent_id_d93c704f; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_parent_id_d93c704f ON public.chat_message USING btree (parent_id);


--
-- Name: chat_message_private_post_id_6d25fa85; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_private_post_id_6d25fa85 ON public.chat_message USING btree (private_post_id);


--
-- Name: chat_message_room_id_5e7d8d78; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_room_id_5e7d8d78 ON public.chat_message USING btree (room_id);


--
-- Name: chat_message_user_id_a47c01bb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_user_id_a47c01bb ON public.chat_message USING btree (user_id);


--
-- Name: chat_message_users_seen_message_message_id_1aab0396; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_users_seen_message_message_id_1aab0396 ON public.chat_message_users_seen_message USING btree (message_id);


--
-- Name: chat_message_users_seen_message_userprofile_id_5ebf085a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_users_seen_message_userprofile_id_5ebf085a ON public.chat_message_users_seen_message USING btree (userprofile_id);


--
-- Name: chat_message_usertags_message_id_d0800f83; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_usertags_message_id_d0800f83 ON public.chat_message_usertags USING btree (message_id);


--
-- Name: chat_message_usertags_userprofile_id_cd5bebf2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_usertags_userprofile_id_cd5bebf2 ON public.chat_message_usertags USING btree (userprofile_id);


--
-- Name: chat_room_administrators_room_id_6134c811; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_administrators_room_id_6134c811 ON public.chat_room_administrators USING btree (room_id);


--
-- Name: chat_room_administrators_userprofile_id_6418a5d0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_administrators_userprofile_id_6418a5d0 ON public.chat_room_administrators USING btree (userprofile_id);


--
-- Name: chat_room_chat_type_6a6866c1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_chat_type_6a6866c1 ON public.chat_room USING btree (chat_type);


--
-- Name: chat_room_chat_type_6a6866c1_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_chat_type_6a6866c1_like ON public.chat_room USING btree (chat_type varchar_pattern_ops);


--
-- Name: chat_room_created_b2a944_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_created_b2a944_brin ON public.chat_room USING brin (created);


--
-- Name: chat_room_interests_interest_id_0bfbb1df; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_interests_interest_id_0bfbb1df ON public.chat_room_interests USING btree (interest_id);


--
-- Name: chat_room_interests_room_id_505611e6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_interests_room_id_505611e6 ON public.chat_room_interests USING btree (room_id);


--
-- Name: chat_room_key_303adb51_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_key_303adb51_like ON public.chat_room USING btree (key varchar_pattern_ops);


--
-- Name: chat_room_last_interaction_068cbf9a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_last_interaction_068cbf9a ON public.chat_room USING btree (last_interaction);


--
-- Name: chat_room_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_location_id ON public.chat_room USING gist (location);


--
-- Name: chat_room_location_id2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_location_id2 ON public.chat_room USING gist (location);


--
-- Name: chat_room_pending_room_id_8c602597; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_pending_room_id_8c602597 ON public.chat_room_pending USING btree (room_id);


--
-- Name: chat_room_pending_userprofile_id_4702fab9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_pending_userprofile_id_4702fab9 ON public.chat_room_pending USING btree (userprofile_id);


--
-- Name: chat_room_place_id_6f634c49; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_place_id_6f634c49 ON public.chat_room USING btree (place_id);


--
-- Name: chat_room_safe_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_safe_location_id ON public.chat_room USING gist (safe_location);


--
-- Name: chat_room_title_trgm_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_title_trgm_index ON public.chat_room USING gin (title public.gin_trgm_ops);


--
-- Name: chat_room_users_room_id_4cd79c94; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_users_room_id_4cd79c94 ON public.chat_room_users USING btree (room_id);


--
-- Name: chat_room_users_userprofile_id_fa87db1d; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_room_users_userprofile_id_fa87db1d ON public.chat_room_users USING btree (userprofile_id);


--
-- Name: comments_co_created_9b07c7_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_co_created_9b07c7_brin ON public.comments_comments USING brin (created);


--
-- Name: comments_comments_downvotes_comments_id_19dfd0d1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_downvotes_comments_id_19dfd0d1 ON public.comments_comments_downvotes USING btree (comments_id);


--
-- Name: comments_comments_downvotes_userprofile_id_492cc36e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_downvotes_userprofile_id_492cc36e ON public.comments_comments_downvotes USING btree (userprofile_id);


--
-- Name: comments_comments_hashtags_comments_id_1bff845c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_hashtags_comments_id_1bff845c ON public.comments_comments_hashtags USING btree (comments_id);


--
-- Name: comments_comments_hashtags_interest_id_c9f06d38; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_hashtags_interest_id_c9f06d38 ON public.comments_comments_hashtags USING btree (interest_id);


--
-- Name: comments_comments_parent_id_d9fe1944; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_parent_id_d9fe1944 ON public.comments_comments USING btree (parent_id);


--
-- Name: comments_comments_post_id_59c014a0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_post_id_59c014a0 ON public.comments_comments USING btree (post_id);


--
-- Name: comments_comments_updated_226efd73; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_updated_226efd73 ON public.comments_comments USING btree (updated);


--
-- Name: comments_comments_upvotes_comments_id_8fe88db6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_upvotes_comments_id_8fe88db6 ON public.comments_comments_upvotes USING btree (comments_id);


--
-- Name: comments_comments_upvotes_userprofile_id_aa67ec5b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_upvotes_userprofile_id_aa67ec5b ON public.comments_comments_upvotes USING btree (userprofile_id);


--
-- Name: comments_comments_user_id_d2c0ea69; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_user_id_d2c0ea69 ON public.comments_comments USING btree (user_id);


--
-- Name: comments_comments_usertags_comments_id_9dd69a72; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_usertags_comments_id_9dd69a72 ON public.comments_comments_usertags USING btree (comments_id);


--
-- Name: comments_comments_usertags_userprofile_id_8548bbde; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comments_comments_usertags_userprofile_id_8548bbde ON public.comments_comments_usertags USING btree (userprofile_id);


--
-- Name: custom_hashtags_value_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX custom_hashtags_value_index ON public.custom_hashtags USING btree (value);


--
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- Name: django_site_domain_a2e37b91_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_site_domain_a2e37b91_like ON public.django_site USING btree (domain varchar_pattern_ops);


--
-- Name: dropchat_elevated_privileges_dropchat_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX dropchat_elevated_privileges_dropchat_id_index ON public.dropchat_elevated_privileges USING btree (dropchat_id);


--
-- Name: dropchat_elevated_privileges_dropchat_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX dropchat_elevated_privileges_dropchat_id_user_id_index ON public.dropchat_elevated_privileges USING btree (dropchat_id, user_id);


--
-- Name: dropchat_elevated_privileges_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX dropchat_elevated_privileges_user_id_index ON public.dropchat_elevated_privileges USING btree (user_id);


--
-- Name: eventbrite_requests_location_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX eventbrite_requests_location_index ON public.eventbrite_requests USING gist (location);


--
-- Name: eventful_requests_location_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX eventful_requests_location_index ON public.eventful_requests USING gist (location);


--
-- Name: events_attendees_event_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_attendees_event_id_user_id_index ON public.events_attendees USING btree (event_id, user_id);


--
-- Name: events_body_tsvector_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_body_tsvector_index ON public.events USING gin (tsvector);


--
-- Name: events_categories_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_categories_index ON public.events USING gin (categories);


--
-- Name: events_eventbrite_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_eventbrite_id_index ON public.events USING btree (eventbrite_id);


--
-- Name: events_eventful_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_eventful_id_index ON public.events USING btree (eventful_id);


--
-- Name: interests_hashtag_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX interests_hashtag_index ON public.interests USING btree (hashtag);


--
-- Name: interests_i_created_c37ac9_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX interests_i_created_c37ac9_brin ON public.interests_interest USING brin (created);


--
-- Name: interests_interest_hashtag_trgm_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX interests_interest_hashtag_trgm_index ON public.interests_interest USING gin (hashtag public.gin_trgm_ops);


--
-- Name: interests_interest_name_4855d67c_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX interests_interest_name_4855d67c_like ON public.interests_interest USING btree (name varchar_pattern_ops);


--
-- Name: interests_interest_updated_2037ab01; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX interests_interest_updated_2037ab01 ON public.interests_interest USING btree (updated);


--
-- Name: interests_u_created_9d3705_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX interests_u_created_9d3705_brin ON public.interests_userinterest USING brin (created);


--
-- Name: interests_userinterest_updated_61ca93b3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX interests_userinterest_updated_61ca93b3 ON public.interests_userinterest USING btree (updated);


--
-- Name: livestream_comments_livestream_id_author_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX livestream_comments_livestream_id_author_id_index ON public.livestream_comments USING btree (livestream_id, author_id);


--
-- Name: livestreams_location_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX livestreams_location_index ON public.livestreams USING gist (location);


--
-- Name: livestreams_owner_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX livestreams_owner_id_index ON public.livestreams USING btree (owner_id);


--
-- Name: livestreams_recorded_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX livestreams_recorded_index ON public.livestreams USING btree ("recorded?");


--
-- Name: notifications_notification_action_object_content_type_7d2b8ee9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_notification_action_object_content_type_7d2b8ee9 ON public.notifications_notification USING btree (action_object_content_type_id);


--
-- Name: notifications_notification_actor_content_type_id_0c69d7b7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_notification_actor_content_type_id_0c69d7b7 ON public.notifications_notification USING btree (actor_content_type_id);


--
-- Name: notifications_notification_recipient_id_d055f3f0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_notification_recipient_id_d055f3f0 ON public.notifications_notification USING btree (recipient_id);


--
-- Name: notifications_notification_target_content_type_id_ccb24d88; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_notification_target_content_type_id_ccb24d88 ON public.notifications_notification USING btree (target_content_type_id);


--
-- Name: places_place_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX places_place_id_index ON public.places USING btree (place_id);


--
-- Name: places_placetype_name_647ccf56_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX places_placetype_name_647ccf56_like ON public.places_placetype USING btree (name varchar_pattern_ops);


--
-- Name: places_types_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX places_types_name_index ON public.places_types USING btree (name);


--
-- Name: polls_body_tsvector_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX polls_body_tsvector_index ON public.polls USING gin (tsvector);


--
-- Name: posts_body_tsvector_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX posts_body_tsvector_index ON public.posts USING gin (tsvector);


--
-- Name: posts_comments_body_tsvector_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX posts_comments_body_tsvector_index ON public.posts_comments USING gin (tsvector);


--
-- Name: posts_eventbrite_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX posts_eventbrite_id_index ON public.posts USING btree (eventbrite_id);


--
-- Name: posts_eventful_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX posts_eventful_id_index ON public.posts USING btree (eventful_id);


--
-- Name: posts_location_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX posts_location_index ON public.posts USING gist (location);


--
-- Name: pst_event_attendees_event_id_48992b46; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_event_attendees_event_id_48992b46 ON public.pst_event_attendees USING btree (event_id);


--
-- Name: pst_event_attendees_userprofile_id_1875941a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_event_attendees_userprofile_id_1875941a ON public.pst_event_attendees USING btree (userprofile_id);


--
-- Name: pst_event_event_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_event_event_location_id ON public.pst_event USING gist (event_location);


--
-- Name: pst_pollitem_poll_id_f1b7e105; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_pollitem_poll_id_f1b7e105 ON public.pst_pollitem USING btree (poll_id);


--
-- Name: pst_pollitem_votes_pollitem_id_b5de4d10; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_pollitem_votes_pollitem_id_b5de4d10 ON public.pst_pollitem_votes USING btree (pollitem_id);


--
-- Name: pst_pollitem_votes_userprofile_id_ec0cf0db; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_pollitem_votes_userprofile_id_ec0cf0db ON public.pst_pollitem_votes USING btree (userprofile_id);


--
-- Name: pst_post_body_tsvector_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_body_tsvector_index ON public.pst_post USING gin (tsv);


--
-- Name: pst_post_created_ad7836_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_created_ad7836_brin ON public.pst_post USING brin (created);


--
-- Name: pst_post_downvotes_post_id_8839e208; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_downvotes_post_id_8839e208 ON public.pst_post_downvotes USING btree (post_id);


--
-- Name: pst_post_downvotes_userprofile_id_905c2f5c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_downvotes_userprofile_id_905c2f5c ON public.pst_post_downvotes USING btree (userprofile_id);


--
-- Name: pst_post_fake_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_fake_location_id ON public.pst_post USING gist (fake_location);


--
-- Name: pst_post_hashtags_interest_id_d1ac07a7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_hashtags_interest_id_d1ac07a7 ON public.pst_post_hashtags USING btree (interest_id);


--
-- Name: pst_post_hashtags_post_id_efc6b901; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_hashtags_post_id_efc6b901 ON public.pst_post_hashtags USING btree (post_id);


--
-- Name: pst_post_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_location_id ON public.pst_post USING gist (location);


--
-- Name: pst_post_location_id2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_location_id2 ON public.pst_post USING gist (location);


--
-- Name: pst_post_parent_id_ea994a8f; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_parent_id_ea994a8f ON public.pst_post USING btree (parent_id);


--
-- Name: pst_post_place_id_cc2ba08c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_place_id_cc2ba08c ON public.pst_post USING btree (place_id);


--
-- Name: pst_post_private_39dd3139; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_private_39dd3139 ON public.pst_post USING btree (private);


--
-- Name: pst_post_title_trgm_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_title_trgm_index ON public.pst_post USING gin (title public.gin_trgm_ops);


--
-- Name: pst_post_updated_67e49ebe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_updated_67e49ebe ON public.pst_post USING btree (updated);


--
-- Name: pst_post_upvotes_post_id_46b87290; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_upvotes_post_id_46b87290 ON public.pst_post_upvotes USING btree (post_id);


--
-- Name: pst_post_upvotes_userprofile_id_a9186571; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_upvotes_userprofile_id_a9186571 ON public.pst_post_upvotes USING btree (userprofile_id);


--
-- Name: pst_post_user_id_3a8be664; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_user_id_3a8be664 ON public.pst_post USING btree (user_id);


--
-- Name: pst_post_usertags_post_id_337c0c95; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_usertags_post_id_337c0c95 ON public.pst_post_usertags USING btree (post_id);


--
-- Name: pst_post_usertags_userprofile_id_ddca37b9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pst_post_usertags_userprofile_id_ddca37b9 ON public.pst_post_usertags USING btree (userprofile_id);


--
-- Name: rihanna_jobs_locking_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rihanna_jobs_locking_index ON public.rihanna_jobs USING btree (priority, due_at, enqueued_at, id);


--
-- Name: upload_file_created_8b16cf_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX upload_file_created_8b16cf_brin ON public.upload_fileupload USING brin (created);


--
-- Name: upload_fileupload_media_key_5622af41_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX upload_fileupload_media_key_5622af41_like ON public.upload_fileupload USING btree (media_key varchar_pattern_ops);


--
-- Name: upload_fileupload_owner_id_611a575b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX upload_fileupload_owner_id_611a575b ON public.upload_fileupload USING btree (owner_id);


--
-- Name: upload_fileupload_updated_b23f70c7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX upload_fileupload_updated_b23f70c7 ON public.upload_fileupload USING btree (updated);


--
-- Name: events events_tsvector_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER events_tsvector_update BEFORE INSERT OR UPDATE ON public.events FOR EACH ROW EXECUTE PROCEDURE public.events_tsvector_update_trigger();


--
-- Name: polls polls_tsvector_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER polls_tsvector_update BEFORE INSERT OR UPDATE ON public.polls FOR EACH ROW EXECUTE PROCEDURE public.polls_tsvector_update_trigger();


--
-- Name: posts_comments posts_comments_tsvector_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER posts_comments_tsvector_update BEFORE INSERT OR UPDATE ON public.posts_comments FOR EACH ROW EXECUTE PROCEDURE public.posts_comments_tsvector_update_trigger();


--
-- Name: posts posts_tsvector_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER posts_tsvector_update BEFORE INSERT OR UPDATE ON public.posts FOR EACH ROW EXECUTE PROCEDURE public.posts_tsvector_update_trigger();


--
-- Name: pst_post pst_post_tsv_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER pst_post_tsv_update BEFORE INSERT OR UPDATE ON public.pst_post FOR EACH ROW EXECUTE PROCEDURE public.pst_post_tsv_update_trigger();


--
-- Name: accounts_invites accounts_invites_user_id_f8798e32_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_invites
    ADD CONSTRAINT accounts_invites_user_id_f8798e32_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_membership accounts_membership_business_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_membership
    ADD CONSTRAINT accounts_membership_business_account_id_fkey FOREIGN KEY (business_account_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: accounts_membership accounts_membership_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_membership
    ADD CONSTRAINT accounts_membership_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: accounts_userfeedback accounts_userfeedbac_feedback_ptr_id_654743c0_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userfeedback
    ADD CONSTRAINT accounts_userfeedbac_feedback_ptr_id_654743c0_fk_accounts_ FOREIGN KEY (feedback_ptr_id) REFERENCES public.accounts_feedback(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userfeedback accounts_userfeedbac_user_id_00952b3e_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userfeedback
    ADD CONSTRAINT accounts_userfeedbac_user_id_00952b3e_fk_accounts_ FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_follows accounts_userprofile_from_userprofile_id_2798b703_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_follows
    ADD CONSTRAINT accounts_userprofile_from_userprofile_id_2798b703_fk_accounts_ FOREIGN KEY (from_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_blocked accounts_userprofile_from_userprofile_id_355dc595_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_blocked
    ADD CONSTRAINT accounts_userprofile_from_userprofile_id_355dc595_fk_accounts_ FOREIGN KEY (from_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_close_friends accounts_userprofile_from_userprofile_id_f1393c0b_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_close_friends
    ADD CONSTRAINT accounts_userprofile_from_userprofile_id_f1393c0b_fk_accounts_ FOREIGN KEY (from_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_groups accounts_userprofile_groups_group_id_74ae51cf_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_groups
    ADD CONSTRAINT accounts_userprofile_groups_group_id_74ae51cf_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_user_permissions accounts_userprofile_permission_id_a9b2b32b_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_user_permissions
    ADD CONSTRAINT accounts_userprofile_permission_id_a9b2b32b_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_blocked accounts_userprofile_to_userprofile_id_53778445_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_blocked
    ADD CONSTRAINT accounts_userprofile_to_userprofile_id_53778445_fk_accounts_ FOREIGN KEY (to_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_follows accounts_userprofile_to_userprofile_id_c73d9228_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_follows
    ADD CONSTRAINT accounts_userprofile_to_userprofile_id_c73d9228_fk_accounts_ FOREIGN KEY (to_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_close_friends accounts_userprofile_to_userprofile_id_f0a3b464_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_close_friends
    ADD CONSTRAINT accounts_userprofile_to_userprofile_id_f0a3b464_fk_accounts_ FOREIGN KEY (to_userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_user_permissions accounts_userprofile_userprofile_id_4acaf5a0_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_user_permissions
    ADD CONSTRAINT accounts_userprofile_userprofile_id_4acaf5a0_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: accounts_userprofile_groups accounts_userprofile_userprofile_id_b7fb6469_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_userprofile_groups
    ADD CONSTRAINT accounts_userprofile_userprofile_id_b7fb6469_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: actstream_action actstream_action_action_object_conten_ee623c15_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actstream_action
    ADD CONSTRAINT actstream_action_action_object_conten_ee623c15_fk_django_co FOREIGN KEY (action_object_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: actstream_action actstream_action_actor_content_type_i_d5e5ec2a_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actstream_action
    ADD CONSTRAINT actstream_action_actor_content_type_i_d5e5ec2a_fk_django_co FOREIGN KEY (actor_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: actstream_action actstream_action_target_content_type__187fa164_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actstream_action
    ADD CONSTRAINT actstream_action_target_content_type__187fa164_fk_django_co FOREIGN KEY (target_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: actstream_follow actstream_follow_content_type_id_ba287eb9_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actstream_follow
    ADD CONSTRAINT actstream_follow_content_type_id_ba287eb9_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: actstream_follow actstream_follow_user_id_e9d4e1ff_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actstream_follow
    ADD CONSTRAINT actstream_follow_user_id_e9d4e1ff_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: appnotifications_device appnotifications_dev_user_id_e281be8a_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appnotifications_device
    ADD CONSTRAINT appnotifications_dev_user_id_e281be8a_fk_accounts_ FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: authtoken_token authtoken_token_user_id_35299eff_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authtoken_token
    ADD CONSTRAINT authtoken_token_user_id_35299eff_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: businesses_categories businesses_categories_business_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.businesses_categories
    ADD CONSTRAINT businesses_categories_business_category_id_fkey FOREIGN KEY (business_category_id) REFERENCES public.business_categories(id);


--
-- Name: businesses_categories businesses_categories_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.businesses_categories
    ADD CONSTRAINT businesses_categories_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id);


--
-- Name: change_password change_password_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.change_password
    ADD CONSTRAINT change_password_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: chat_message_custom_hashtags chat_message_custom_hashtags_hashtag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_custom_hashtags
    ADD CONSTRAINT chat_message_custom_hashtags_hashtag_id_fkey FOREIGN KEY (hashtag_id) REFERENCES public.custom_hashtags(id) ON DELETE CASCADE;


--
-- Name: chat_message_custom_hashtags chat_message_custom_hashtags_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_custom_hashtags
    ADD CONSTRAINT chat_message_custom_hashtags_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.chat_message(id) ON DELETE CASCADE;


--
-- Name: chat_message chat_message_forwarded_message_id_3a06f552_fk_chat_message_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_forwarded_message_id_3a06f552_fk_chat_message_id FOREIGN KEY (forwarded_message_id) REFERENCES public.chat_message(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_hashtags chat_message_hashtag_interest_id_3116b459_fk_interests; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_hashtags
    ADD CONSTRAINT chat_message_hashtag_interest_id_3116b459_fk_interests FOREIGN KEY (interest_id) REFERENCES public.interests_interest(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_hashtags chat_message_hashtags_message_id_80415300_fk_chat_message_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_hashtags
    ADD CONSTRAINT chat_message_hashtags_message_id_80415300_fk_chat_message_id FOREIGN KEY (message_id) REFERENCES public.chat_message(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message chat_message_parent_id_d93c704f_fk_chat_message_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_parent_id_d93c704f_fk_chat_message_id FOREIGN KEY (parent_id) REFERENCES public.chat_message(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message chat_message_private_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_private_post_id_fkey FOREIGN KEY (private_post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: chat_message chat_message_room_id_5e7d8d78_fk_chat_room_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_room_id_5e7d8d78_fk_chat_room_id FOREIGN KEY (room_id) REFERENCES public.chat_room(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message chat_message_user_id_a47c01bb_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_user_id_a47c01bb_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_users_seen_message chat_message_users_s_message_id_1aab0396_fk_chat_mess; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_users_seen_message
    ADD CONSTRAINT chat_message_users_s_message_id_1aab0396_fk_chat_mess FOREIGN KEY (message_id) REFERENCES public.chat_message(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_users_seen_message chat_message_users_s_userprofile_id_5ebf085a_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_users_seen_message
    ADD CONSTRAINT chat_message_users_s_userprofile_id_5ebf085a_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_usertags chat_message_usertag_userprofile_id_cd5bebf2_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_usertags
    ADD CONSTRAINT chat_message_usertag_userprofile_id_cd5bebf2_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_message_usertags chat_message_usertags_message_id_d0800f83_fk_chat_message_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_usertags
    ADD CONSTRAINT chat_message_usertags_message_id_d0800f83_fk_chat_message_id FOREIGN KEY (message_id) REFERENCES public.chat_message(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_administrators chat_room_administra_userprofile_id_6418a5d0_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_administrators
    ADD CONSTRAINT chat_room_administra_userprofile_id_6418a5d0_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_administrators chat_room_administrators_room_id_6134c811_fk_chat_room_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_administrators
    ADD CONSTRAINT chat_room_administrators_room_id_6134c811_fk_chat_room_id FOREIGN KEY (room_id) REFERENCES public.chat_room(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room chat_room_interest_id_c29af3f3_fk_interests_interest_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room
    ADD CONSTRAINT chat_room_interest_id_c29af3f3_fk_interests_interest_id FOREIGN KEY (interest_id) REFERENCES public.interests_interest(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_interests chat_room_interests_interest_id_0bfbb1df_fk_interests; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_interests
    ADD CONSTRAINT chat_room_interests_interest_id_0bfbb1df_fk_interests FOREIGN KEY (interest_id) REFERENCES public.interests_interest(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_interests chat_room_interests_room_id_505611e6_fk_chat_room_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_interests
    ADD CONSTRAINT chat_room_interests_room_id_505611e6_fk_chat_room_id FOREIGN KEY (room_id) REFERENCES public.chat_room(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_pending chat_room_pending_room_id_8c602597_fk_chat_room_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_pending
    ADD CONSTRAINT chat_room_pending_room_id_8c602597_fk_chat_room_id FOREIGN KEY (room_id) REFERENCES public.chat_room(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_pending chat_room_pending_userprofile_id_4702fab9_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_pending
    ADD CONSTRAINT chat_room_pending_userprofile_id_4702fab9_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room chat_room_place_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room
    ADD CONSTRAINT chat_room_place_id_fkey FOREIGN KEY (place_id) REFERENCES public.places(id);


--
-- Name: chat_room_users chat_room_users_room_id_4cd79c94_fk_chat_room_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_users
    ADD CONSTRAINT chat_room_users_room_id_4cd79c94_fk_chat_room_id FOREIGN KEY (room_id) REFERENCES public.chat_room(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: chat_room_users chat_room_users_userprofile_id_fa87db1d_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_room_users
    ADD CONSTRAINT chat_room_users_userprofile_id_fa87db1d_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comment_uploads comment_uploads_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_uploads
    ADD CONSTRAINT comment_uploads_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.posts_comments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: comment_uploads comment_uploads_upload_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_uploads
    ADD CONSTRAINT comment_uploads_upload_key_fkey FOREIGN KEY (upload_key) REFERENCES public.upload_fileupload(media_key) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: comments_comments_downvotes comments_comments_do_comments_id_19dfd0d1_fk_comments_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_downvotes
    ADD CONSTRAINT comments_comments_do_comments_id_19dfd0d1_fk_comments_ FOREIGN KEY (comments_id) REFERENCES public.comments_comments(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_downvotes comments_comments_do_userprofile_id_492cc36e_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_downvotes
    ADD CONSTRAINT comments_comments_do_userprofile_id_492cc36e_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_hashtags comments_comments_ha_comments_id_1bff845c_fk_comments_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_hashtags
    ADD CONSTRAINT comments_comments_ha_comments_id_1bff845c_fk_comments_ FOREIGN KEY (comments_id) REFERENCES public.comments_comments(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_hashtags comments_comments_ha_interest_id_c9f06d38_fk_interests; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_hashtags
    ADD CONSTRAINT comments_comments_ha_interest_id_c9f06d38_fk_interests FOREIGN KEY (interest_id) REFERENCES public.interests_interest(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments comments_comments_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments
    ADD CONSTRAINT comments_comments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.comments_comments(id);


--
-- Name: comments_comments comments_comments_post_id_59c014a0_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments
    ADD CONSTRAINT comments_comments_post_id_59c014a0_fk_pst_post_id FOREIGN KEY (post_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_upvotes comments_comments_up_comments_id_8fe88db6_fk_comments_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_upvotes
    ADD CONSTRAINT comments_comments_up_comments_id_8fe88db6_fk_comments_ FOREIGN KEY (comments_id) REFERENCES public.comments_comments(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_upvotes comments_comments_up_userprofile_id_aa67ec5b_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_upvotes
    ADD CONSTRAINT comments_comments_up_userprofile_id_aa67ec5b_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_usertags comments_comments_us_comments_id_9dd69a72_fk_comments_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_usertags
    ADD CONSTRAINT comments_comments_us_comments_id_9dd69a72_fk_comments_ FOREIGN KEY (comments_id) REFERENCES public.comments_comments(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments_usertags comments_comments_us_userprofile_id_8548bbde_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments_usertags
    ADD CONSTRAINT comments_comments_us_userprofile_id_8548bbde_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: comments_comments comments_comments_user_id_d2c0ea69_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments_comments
    ADD CONSTRAINT comments_comments_user_id_d2c0ea69_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_user_id_c564eba6_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: dropchat_elevated_privileges dropchat_elevated_privileges_dropchat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dropchat_elevated_privileges
    ADD CONSTRAINT dropchat_elevated_privileges_dropchat_id_fkey FOREIGN KEY (dropchat_id) REFERENCES public.chat_room(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dropchat_elevated_privileges dropchat_elevated_privileges_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dropchat_elevated_privileges
    ADD CONSTRAINT dropchat_elevated_privileges_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: event_uploads event_uploads_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_uploads
    ADD CONSTRAINT event_uploads_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: event_uploads event_uploads_upload_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_uploads
    ADD CONSTRAINT event_uploads_upload_key_fkey FOREIGN KEY (upload_key) REFERENCES public.upload_fileupload(media_key) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: events_attendees events_attendees_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_attendees
    ADD CONSTRAINT events_attendees_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: events_attendees events_attendees_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_attendees
    ADD CONSTRAINT events_attendees_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: events events_place_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_place_id_fkey FOREIGN KEY (place_id) REFERENCES public.places(id);


--
-- Name: interests_userinterest interests_userintere_user_id_bffd376a_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests_userinterest
    ADD CONSTRAINT interests_userintere_user_id_bffd376a_fk_accounts_ FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: interests_userinterest interests_userinterest_interest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interests_userinterest
    ADD CONSTRAINT interests_userinterest_interest_id_fkey FOREIGN KEY (interest_id) REFERENCES public.interests(id) ON DELETE CASCADE;


--
-- Name: livestream_comment_votes livestream_comment_votes_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_comment_votes
    ADD CONSTRAINT livestream_comment_votes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.livestream_comments(id) ON DELETE CASCADE;


--
-- Name: livestream_comment_votes livestream_comment_votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_comment_votes
    ADD CONSTRAINT livestream_comment_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: livestream_comments livestream_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_comments
    ADD CONSTRAINT livestream_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: livestream_comments livestream_comments_livestream_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_comments
    ADD CONSTRAINT livestream_comments_livestream_id_fkey FOREIGN KEY (livestream_id) REFERENCES public.livestreams(id) ON DELETE CASCADE;


--
-- Name: livestream_views livestream_views_livestream_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_views
    ADD CONSTRAINT livestream_views_livestream_id_fkey FOREIGN KEY (livestream_id) REFERENCES public.livestreams(id) ON DELETE CASCADE;


--
-- Name: livestream_views livestream_views_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_views
    ADD CONSTRAINT livestream_views_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: livestream_votes livestream_votes_livestream_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_votes
    ADD CONSTRAINT livestream_votes_livestream_id_fkey FOREIGN KEY (livestream_id) REFERENCES public.livestreams(id) ON DELETE CASCADE;


--
-- Name: livestream_votes livestream_votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestream_votes
    ADD CONSTRAINT livestream_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: livestreams livestreams_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.livestreams
    ADD CONSTRAINT livestreams_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: message_uploads message_uploads_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_uploads
    ADD CONSTRAINT message_uploads_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.chat_message(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message_uploads message_uploads_upload_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_uploads
    ADD CONSTRAINT message_uploads_upload_key_fkey FOREIGN KEY (upload_key) REFERENCES public.upload_fileupload(media_key) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: notifications_notification notifications_notifi_action_object_conten_7d2b8ee9_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notifi_action_object_conten_7d2b8ee9_fk_django_co FOREIGN KEY (action_object_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: notifications_notification notifications_notifi_actor_content_type_i_0c69d7b7_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notifi_actor_content_type_i_0c69d7b7_fk_django_co FOREIGN KEY (actor_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: notifications_notification notifications_notifi_recipient_id_d055f3f0_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notifi_recipient_id_d055f3f0_fk_accounts_ FOREIGN KEY (recipient_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: notifications_notification notifications_notifi_target_content_type__ccb24d88_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_notification
    ADD CONSTRAINT notifications_notifi_target_content_type__ccb24d88_fk_django_co FOREIGN KEY (target_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: places_typeship places_typeship_place_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places_typeship
    ADD CONSTRAINT places_typeship_place_id_fkey FOREIGN KEY (place_id) REFERENCES public.places(id) ON DELETE CASCADE;


--
-- Name: places_typeship places_typeship_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.places_typeship
    ADD CONSTRAINT places_typeship_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.places_types(id) ON DELETE CASCADE;


--
-- Name: poll_item_uploads poll_item_uploads_poll_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_item_uploads
    ADD CONSTRAINT poll_item_uploads_poll_item_id_fkey FOREIGN KEY (poll_item_id) REFERENCES public.polls_items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: poll_item_uploads poll_item_uploads_upload_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_item_uploads
    ADD CONSTRAINT poll_item_uploads_upload_key_fkey FOREIGN KEY (upload_key) REFERENCES public.upload_fileupload(media_key) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: poll_items poll_items_poll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_items
    ADD CONSTRAINT poll_items_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES public.poll(id);


--
-- Name: poll poll_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll
    ADD CONSTRAINT poll_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.pst_post(id);


--
-- Name: polls_items polls_items_poll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls_items
    ADD CONSTRAINT polls_items_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES public.polls(id) ON DELETE CASCADE;


--
-- Name: polls_items_votes polls_items_votes_poll_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls_items_votes
    ADD CONSTRAINT polls_items_votes_poll_item_id_fkey FOREIGN KEY (poll_item_id) REFERENCES public.polls_items(id) ON DELETE CASCADE;


--
-- Name: polls_items_votes polls_items_votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls_items_votes
    ADD CONSTRAINT polls_items_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: polls polls_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT polls_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: post_approval_request post_approval_request_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_approval_request
    ADD CONSTRAINT post_approval_request_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: post_approval_request post_approval_request_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_approval_request
    ADD CONSTRAINT post_approval_request_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: post_approval_request_rejection post_approval_request_rejection_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_approval_request_rejection
    ADD CONSTRAINT post_approval_request_rejection_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: post_approval_request_rejection post_approval_request_rejection_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_approval_request_rejection
    ADD CONSTRAINT post_approval_request_rejection_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: post_approval_request_rejection post_approval_request_rejection_requester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_approval_request_rejection
    ADD CONSTRAINT post_approval_request_rejection_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: post_approval_request post_approval_request_requester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_approval_request
    ADD CONSTRAINT post_approval_request_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: post_uploads post_uploads_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_uploads
    ADD CONSTRAINT post_uploads_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: post_uploads post_uploads_upload_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_uploads
    ADD CONSTRAINT post_uploads_upload_key_fkey FOREIGN KEY (upload_key) REFERENCES public.upload_fileupload(media_key) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: posts posts_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.accounts_userprofile(id);


--
-- Name: posts posts_business_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_business_admin_id_fkey FOREIGN KEY (business_admin_id) REFERENCES public.accounts_userprofile(id);


--
-- Name: posts posts_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.accounts_userprofile(id);


--
-- Name: posts_comments posts_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments
    ADD CONSTRAINT posts_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.accounts_userprofile(id);


--
-- Name: posts_comments_downvotes posts_comments_downvotes_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_downvotes
    ADD CONSTRAINT posts_comments_downvotes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.posts_comments(id) ON DELETE CASCADE;


--
-- Name: posts_comments_downvotes posts_comments_downvotes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_downvotes
    ADD CONSTRAINT posts_comments_downvotes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: posts_comments_interests posts_comments_interests_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_interests
    ADD CONSTRAINT posts_comments_interests_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.posts_comments(id) ON DELETE CASCADE;


--
-- Name: posts_comments_interests posts_comments_interests_interest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_interests
    ADD CONSTRAINT posts_comments_interests_interest_id_fkey FOREIGN KEY (interest_id) REFERENCES public.interests(id) ON DELETE CASCADE;


--
-- Name: posts_comments posts_comments_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments
    ADD CONSTRAINT posts_comments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.posts_comments(id) ON DELETE CASCADE;


--
-- Name: posts_comments posts_comments_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments
    ADD CONSTRAINT posts_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: posts_comments_upvotes posts_comments_upvotes_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_upvotes
    ADD CONSTRAINT posts_comments_upvotes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.posts_comments(id) ON DELETE CASCADE;


--
-- Name: posts_comments_upvotes posts_comments_upvotes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_comments_upvotes
    ADD CONSTRAINT posts_comments_upvotes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: posts_downvotes posts_downvotes_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_downvotes
    ADD CONSTRAINT posts_downvotes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: posts_downvotes posts_downvotes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_downvotes
    ADD CONSTRAINT posts_downvotes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: events posts_events_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT posts_events_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: posts_interests posts_interests_interest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_interests
    ADD CONSTRAINT posts_interests_interest_id_fkey FOREIGN KEY (interest_id) REFERENCES public.interests(id) ON DELETE CASCADE;


--
-- Name: posts_interests posts_interests_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_interests
    ADD CONSTRAINT posts_interests_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: posts posts_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: posts posts_place_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_place_id_fkey FOREIGN KEY (place_id) REFERENCES public.places(id);


--
-- Name: posts_upvotes posts_upvotes_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_upvotes
    ADD CONSTRAINT posts_upvotes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: posts_upvotes posts_upvotes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts_upvotes
    ADD CONSTRAINT posts_upvotes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) ON DELETE CASCADE;


--
-- Name: pst_event_attendees pst_event_attendees_event_id_48992b46_fk_pst_event_post_ptr_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_event_attendees
    ADD CONSTRAINT pst_event_attendees_event_id_48992b46_fk_pst_event_post_ptr_id FOREIGN KEY (event_id) REFERENCES public.pst_event(post_ptr_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_event_attendees pst_event_attendees_userprofile_id_1875941a_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_event_attendees
    ADD CONSTRAINT pst_event_attendees_userprofile_id_1875941a_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_event pst_event_post_ptr_id_77bcaabd_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_event
    ADD CONSTRAINT pst_event_post_ptr_id_77bcaabd_fk_pst_post_id FOREIGN KEY (post_ptr_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_poll pst_poll_post_ptr_id_0b510052_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_poll
    ADD CONSTRAINT pst_poll_post_ptr_id_0b510052_fk_pst_post_id FOREIGN KEY (post_ptr_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_pollitem pst_pollitem_poll_id_f1b7e105_fk_pst_poll_post_ptr_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_pollitem
    ADD CONSTRAINT pst_pollitem_poll_id_f1b7e105_fk_pst_poll_post_ptr_id FOREIGN KEY (poll_id) REFERENCES public.pst_poll(post_ptr_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_pollitem_votes pst_pollitem_votes_pollitem_id_b5de4d10_fk_pst_pollitem_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_pollitem_votes
    ADD CONSTRAINT pst_pollitem_votes_pollitem_id_b5de4d10_fk_pst_pollitem_id FOREIGN KEY (pollitem_id) REFERENCES public.pst_pollitem(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_pollitem_votes pst_pollitem_votes_userprofile_id_ec0cf0db_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_pollitem_votes
    ADD CONSTRAINT pst_pollitem_votes_userprofile_id_ec0cf0db_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post pst_post_business_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post
    ADD CONSTRAINT pst_post_business_admin_id_fkey FOREIGN KEY (business_admin_id) REFERENCES public.accounts_userprofile(id);


--
-- Name: pst_post_downvotes pst_post_downvotes_post_id_8839e208_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_downvotes
    ADD CONSTRAINT pst_post_downvotes_post_id_8839e208_fk_pst_post_id FOREIGN KEY (post_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_downvotes pst_post_downvotes_userprofile_id_905c2f5c_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_downvotes
    ADD CONSTRAINT pst_post_downvotes_userprofile_id_905c2f5c_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_hashtags pst_post_hashtags_post_id_efc6b901_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_hashtags
    ADD CONSTRAINT pst_post_hashtags_post_id_efc6b901_fk_pst_post_id FOREIGN KEY (post_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post pst_post_parent_id_ea994a8f_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post
    ADD CONSTRAINT pst_post_parent_id_ea994a8f_fk_pst_post_id FOREIGN KEY (parent_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post pst_post_place_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post
    ADD CONSTRAINT pst_post_place_id_fkey FOREIGN KEY (place_id) REFERENCES public.places(id);


--
-- Name: pst_post_report pst_post_report_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_report
    ADD CONSTRAINT pst_post_report_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.pst_post(id);


--
-- Name: pst_post_report pst_post_report_reason_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_report
    ADD CONSTRAINT pst_post_report_reason_id_fkey FOREIGN KEY (reason_id) REFERENCES public.pst_post_report_reason(id);


--
-- Name: pst_post_report pst_post_report_reporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_report
    ADD CONSTRAINT pst_post_report_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.accounts_userprofile(id);


--
-- Name: pst_post_upvotes pst_post_upvotes_post_id_46b87290_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_upvotes
    ADD CONSTRAINT pst_post_upvotes_post_id_46b87290_fk_pst_post_id FOREIGN KEY (post_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_upvotes pst_post_upvotes_userprofile_id_a9186571_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_upvotes
    ADD CONSTRAINT pst_post_upvotes_userprofile_id_a9186571_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post pst_post_user_id_3a8be664_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post
    ADD CONSTRAINT pst_post_user_id_3a8be664_fk_accounts_userprofile_id FOREIGN KEY (user_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_usertags pst_post_usertags_post_id_337c0c95_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_usertags
    ADD CONSTRAINT pst_post_usertags_post_id_337c0c95_fk_pst_post_id FOREIGN KEY (post_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_post_usertags pst_post_usertags_userprofile_id_ddca37b9_fk_accounts_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_post_usertags
    ADD CONSTRAINT pst_post_usertags_userprofile_id_ddca37b9_fk_accounts_ FOREIGN KEY (userprofile_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pst_votepost pst_votepost_post_ptr_id_b1c474f2_fk_pst_post_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pst_votepost
    ADD CONSTRAINT pst_votepost_post_ptr_id_b1c474f2_fk_pst_post_id FOREIGN KEY (post_ptr_id) REFERENCES public.pst_post(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: upload_fileupload upload_fileupload_owner_id_611a575b_fk_accounts_userprofile_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.upload_fileupload
    ADD CONSTRAINT upload_fileupload_owner_id_611a575b_fk_accounts_userprofile_id FOREIGN KEY (owner_id) REFERENCES public.accounts_userprofile(id) DEFERRABLE INITIALLY DEFERRED;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20180312185615), (20180328141954), (20180503165013), (20180504091456), (20180505080318), (20180505113737), (20180505122358), (20180509110838), (20180525071413), (20180529090417), (20180529090438), (20180612055159), (20180612055507), (20180615150106), (20180615150310), (20180615201318), (20180615202238), (20180615203744), (20180615203925), (20180615210659), (20180620121411), (20180625062110), (20180911132943), (20180929144908), (20180929144936), (20181001151925), (20190104125926), (20190106005210), (20190106135456), (20190211101215), (20190211113355), (20190211122344), (20190314205444), (20190314221100), (20190315144915), (20190315144916), (20190415145115), (20190517102714), (20190529210849), (20190531201043), (20190601131330), (20190606180922), (20190606213331), (20190606214232), (20190606220344), (20190607032553), (20190607033717), (20190607034306), (20190607034311), (20190608010811), (20190608011411), (20190608013257), (20190608064955), (20190608070823), (20190608085947), (20190608105727), (20190609201647), (20190609202653), (20190610042522), (20190611094841), (20190611103039), (20190611104450), (20190611111520), (20190611172453), (20190612000349), (20190612001557), (20190612002153), (20190612003059), (20190612010710), (20190612011237), (20190613193756), (20190614004946), (20190616050438), (20190802092916), (20190804074014), (20190804132951), (20190804142824), (20190804195705), (20190810082907), (20190811124956), (20190811164339), (20190814175611), (20190819154000), (20190820145250), (20190820150352), (20190820150455), (20190820174547), (20190820193410), (20190903103916), (20190903103917), (20190903103937), (20190903104007), (20190903130827), (20191023115242), (20191105202032), (20191105202241), (20191106135935), (20191106143905), (20191106145930), (20191106202935), (20191114144420), (20191114163633), (20191120153622), (20191123155056), (20191205143730), (20191209111717), (20191209120458), (20191209120509), (20200112155825), (20200112173536), (20200112180422);

