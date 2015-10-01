# check_passenger

[![Gem Version](https://badge.fury.io/rb/check_passenger.svg)](http://badge.fury.io/rb/check_passenger)
[![Build Status](https://travis-ci.org/aredondo/check_passenger.svg?branch=master)](https://travis-ci.org/aredondo/check_passenger)
[![Code Climate](https://codeclimate.com/github/aredondo/check_passenger/badges/gpa.svg)](https://codeclimate.com/github/aredondo/check_passenger)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://aredondo.mit-license.org)

This gem provides a Nagios check command to monitor running Passenger processes and the memory that they use.

It can report data on a global or per-application basis, and raise warnings and alerts when consumption exceeds given thresholds.


## Installation

The easiest way to install **check\_passenger** is through RubyGems:

    # gem install check_passenger

Alternatively, the gem can be built from the source code with `gem build`, and manually installed in the machines where it needs to run.

Either way, the `check_passenger` command should become available in the path—although it may be necessary to perform an additional action, such as running `rbenv rehash` or similar.

This gem requires Ruby 1.9+.


## Usage

**check\_passenger** is intended to be executed in the same machine or machines where Passenger is running. It will call `passenger-status` and gather all data from its output.

Typically, the Nagios service will be running in a separate machine from those being monitored. Remote execution of **check\_passenger** is then usually achieved with Nagios Remote Plugin Executor (NRPE), or MK's Remote Plugin Executor (MRPE).

**check\_passenger** reads all necessary settings from the command-line when it's run, and does not take configuration from a file. It supports several working modes, one for each aspect that can be monitored, which are called with an argument as:

    # check_passenger <mode>

Where the `<mode>` argument can be one of the following:

* `processes`: These are the Passenger processes that are currently running, associated to applications.
* `live_processes`: Of all the running processes, how many are actually being used. See the section [Passenger Live Processes](#passenger-live-processes) below.
* `memory`: Memory occupied by the Passenger processes that are running.
* `requests`: Number of requests that are waiting in application queues. See the section [Passenger Request Queues](#passenger-request-queues) below.
* `top_level_requests`: Number of requests waiting in the top-level queue. See the section [Passenger Request Queues](#passenger-request-queues) below.

When checking for `processes`, `live_processes`, `memory`, or `requests`—that is, any check type except for `top_level_requests`—, the following options can be provided to filter data by application, or to get separate counters for each running application:

* `-n, --app-name`: Limit check to application with *APP_NAME*—see the section [Global or Per-Application Reporting](#global-or-per-application-reporting) below.
* `-a, --include-all`: Apart from reporting on a global counter, add data for the same counter for each running Passenger application—see the section [Global or Per-Application Reporting](#global-or-per-application-reporting) below.

These two options are mutually exclusive.

In addition, **check\_passenger** can be called with the following options for any check type:

* `-C, --cache`: Cache parsed output of `passenger-status`—see the section [Data Caching](#data-caching) below.
* `-D, --debug`: Let exception raise to the command-line, and keep the output of `passenger-status` in a file for debugging purposes.
* `-d, --dump`: Keep the output of `passenger-status` in a file for debugging purposes.
* `-p, --passenger-status-path`: Full path to the `passenger-status` command—most of the time not needed.

To raise warnings and alerts, use the `-w, --warn`, and `-c, --crit` options. Ranges can be provided as described in the [Nagios Plugin Development Guidelines](https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT). Note that memory is measured in megabytes.

Finally, run `check_passenger help [mode]` to get usage information on the command-line.


## Global or Per-Application Reporting

For most of the aspects that **check\_passenger** can monitor (processes, live processes, application request queue size, and memory), it can focus on all the applications running with Passenger, or on a specific application. This is controlled with the `-n` (`--app-name`), and `-a` (`--include-all`) options, as seen in the following examples.

The following command returns a counter for all the running Passenger processes in the machine:

    # check_passenger processes
    Passenger 4.0.59 OK - 46 processes|process_count=46;;;0;50

The next command limits the count to the processes that belong to *APP_NAME*:

    # check_passenger processes --app-name APP_NAME
    Passenger APP_NAME OK - 20 processes|process_count=20;;;0;

Where *APP_NAME* is the full path, or a unique part of it, to the root directory of the application. If, for example, each application is installed in its own user directory, this path could be something like `/home/USER/Site`, and only the username would be needed to filter the output for the application—but the full path could be provided.

If multiple applications match the *APP_NAME* given, **check\_passenger** reports an `UNKNOWN` status. If no application is found by the search string, it is assumed that the application failed and is not running, so **check\_passenger** raises a critical alert.

Finally, it's possible to obtain a global counter, together with additional counters for each running application, as follows:

    # check_passenger processes --include-all
    Passenger 4.0.59 OK - 46 processes|process_count=46;;;0;50 /home/APP_NAME_1/Site=20;;;; /home/APP_NAME_2/Site=12;;;; /home/APP_NAME_3/Site=4;;;; /home/APP_NAME_4/Site=10;;;;
    /home/APP_NAME_1/Site 20 processes
    /home/APP_NAME_2/Site 12 processes
    /home/APP_NAME_3/Site 4 processes
    /home/APP_NAME_4/Site 10 processes

This allows to monitor a resource, together with how much of it is being used by each application. Note though, that when monitoring a particular counter for all the applications in this way, it won't be possible to set alerts—just add an additional check for the alert you want to set for an application or globally.

All these examples work the same with processes, live processes, request queue size, and memory. The exception is the check for requests waiting in the top-level queue, which is just a global counter.


## Passenger Live Processes

Passenger reuses running processes in a sort of LIFO manner. This means that when it needs a process to handle a request, and there are running processes not currently busy handling requests, it will preferably take first the one that was run the most recently. This feature is quite handy to know how many processes a particular application, or all running applications, actually ever execute in parallel.

In order to estimate the live process count, **check\_passenger** takes a look at those that have been run in the last 300 seconds (or 5 minutes). This works well as long as **check\_passenger** is executed with a periodicity of 5 minutes or less.


## Passenger Request Queues

> Phusion Passenger's internal state consists of a list of Groups (representing applications), each which consist of a list of Processes (representing application processes). When spawning the first process for an application, Phusion Passenger has to create and initialize a Group data structure, run hooks, etc. Since this involves reading from disk and running processes, it can potentially take an arbitrary amount of time. During that time, said request, and any new requests targeted at that application, are put in the top-level queue until the Group is done initializing.

> Each Group has its own queue. As soon as the Group is initialized, relevant requests from the top-level queue are moved to the Group-local queue. This is the reason why the top-level queue is usually empty. The sum of the values of all Group-local queues, plus the value of the top-level queue, is the total number of requests that are queued. In general, if they are non-zero and increasing, the number of workers needs to be increased.

Hongli. (2014, April 12). Re: Difference between "requests in top-level queue" and "requests in queue" in Phusion Passenger [Online forum comment]. Retrieved from http://stackoverflow.com/questions/23025028/difference-between-requests-in-top-level-queue-and-requests-in-queue-in-phus

Three different queued requests counters can be monitored:

* The total number of queued requests: `check_passenger requests`. This is the sum of the top-level queued requests, plus the requests queued in every application group.
* The number of requests queued for a specific application: `check_passenger requests --app-name APP_NAME`
* The number of requests waiting in the top-level queue: `check_passenger top_level_requests`

According to the [Phusion Passenger documentation](https://www.phusionpassenger.com/library/admin/apache/overall_status_report.html#viewing-process-and-request-queue-information), the top-level request queue size is supposed to be almost always zero. If it is non-zero for an extended period of time, then there is something very wrong, possibly a Passenger bug.


## Data Caching

In order to set alerts per global or application counter, **check\_passenger** must be called successive times with different settings. For example, to raise alerts on global memory consumption:

    # check_passenger memory --warn 6000 --crit 8000
    Passenger 4.0.59 OK - 4864MB memory used|memory=4864;6000;8000;0;

And then again, to raise alerts on the memory consumption of a specific application:

    # check_passenger memory --app-name APP_NAME --warn 3000 --crit 4000
    Passenger APP_NAME OK - 2123MB memory used|memory=2123;3000;4000;0;

For each call, **check\_passenger** must execute `passenger-status` and parse its output. While the performance penalty should not be high, this can lead to inconsistent data where, for example, the global process count is not equal to the sum of processes for all applications, as it's possible for processes to be started or terminated between calls.

To avoid this inconsistency, and speed things up a bit in the way, **check\_passenger** can cache the parsed output of `passenger-status`. Just provide the `-C`, or `--cache` command-line option.

Cached data is stored in the temporary directory of the system, with a time-to-live of just 5 seconds. That is, cached data will be ignored if it's more than 5 seconds old. Therefore, it's recommended that all calls to **check\_passenger** are made one after another, without inserting other checks in the middle that might take longer to complete.


## Contributing

1. Fork it ( https://github.com/aredondo/check_passenger/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


## License

**check\_passenger** is released under the [MIT License](LICENSE.txt).
