#!/bin/bash

version=".1"

. /srv/http/functions.sh
title="$HOSTNAME - running $RELEASE_PRETTY_NAME"
time=$(date +'%r')
date=$(date +'%B %d, %Y')
pretty_time="It's currently $time, on $date."
content_type html

cat <<EOF
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>$title</title>
        <!-- Bootstrap -->
        <link href="/css/bootstrap.min.css" rel="stylesheet">
        <link href="/css/bootstrap-theme.min.css" rel="stylesheet">
        <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
        <!-- WARNING: Respond.js does not work if you view the page via file:// -->
        <!--[if lt IE 9]>
            <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
            <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
        <![endif]-->
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
        <script src="/js/bootstrap.min.js"></script>
    </head>
    <body>
        <div class='container'>
            <header class='page-header'>
                <h1>$HOSTNAME <small>running $RELEASE_PRETTY_NAME</small></h1>
                <h4>$pretty_time <small>raspui v$version</small></h4>
            </header>
            <div class="row">
                <div class="col-md-4">.col-md-4</div>
                <div class="col-md-4">.col-md-4</div>
                <div class="col-md-4">.col-md-4</div>
            </div>
        </div>
    </body>
</html>
EOF