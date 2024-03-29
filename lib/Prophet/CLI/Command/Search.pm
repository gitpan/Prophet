package Prophet::CLI::Command::Search;
{
  $Prophet::CLI::Command::Search::VERSION = '0.751';
}
use Any::Moose;
extends 'Prophet::CLI::Command';
with 'Prophet::CLI::RecordCommand';
with 'Prophet::CLI::CollectionCommand';

has '+uuid' => ( required => 0 );

has 'sort_routine' => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 0,

    # default subs are executed immediately, hence the weird syntax for coderefs
    default => sub {
        sub {
            my $records = shift;
            return ( sort { $a->luid <=> $b->luid } @$records );
          }
    },
    documentation =>
      'A subroutine which takes a arrayref to a list of records and returns them sorted in some way.',
);

has group_routine => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 0,
    default  => sub {
        sub {
            my $records = shift;
            return [ { label => '', records => $records } ];
          }
    },
    documentation =>
      'A subroutine which takes an arrayref to a list of records and returns an array of hashrefs  { label => $label, records => \@array}'
);

sub usage_msg {
    my $self = shift;
    my ( $cmd, $type_and_subcmd ) = $self->get_cmd_and_subcmd_names;

    return <<"END_USAGE";
usage: ${cmd}${type_and_subcmd}
       ${cmd}${type_and_subcmd} -- prop1=~foo prop2!~bar|baz
END_USAGE
}

sub default_match {1}

sub get_search_callback {
    my $self = shift;

    my %prop_checks;
    for my $check ( $self->prop_set ) {
        push @{ $prop_checks{ $check->{prop} } }, $check;
    }

    my $regex = $self->arg('regex');

    return sub {
        my $item      = shift;
        my $props     = $item->get_props;
        my $did_limit = 0;

        if ( $self->prop_names > 0 ) {
            $did_limit = 1;

            for my $prop ( keys %prop_checks ) {
                my $got = $props->{$prop};
                my $ok  = 0;
                for my $check ( @{ $prop_checks{$prop} } ) {
                    $ok = 1
                      if $self->_compare( $check->{value}, $check->{cmp},
                        $got );
                }
                return 0 if !$ok;
            }
        }

        # if they specify a regex, it must match
        if ($regex) {
            $did_limit = 1;
            my $ok = 0;

            for ( values %$props ) {
                if (/$regex/) {
                    $ok = 1;
                    last;
                }
            }
            return 0 if !$ok;
        }

        return $self->default_match($item) if !$did_limit;

        return 1;
    };
}

sub _compare {
    my $self = shift;
    my ( $expected, $cmp, $got ) = @_;

    $got = '' if !defined($got);    # avoid undef warnings

    if ( $cmp eq '=' ) {
        return 0 unless $got eq $expected;
    } elsif ( $cmp eq '=~' ) {
        return 0 unless $got =~ $expected;
    } elsif ( $cmp eq '!=' || $cmp eq '<>' || $cmp eq 'ne' ) {
        return 0 if $got eq $expected;
    } elsif ( $cmp eq '!~' ) {
        return 0 if $got =~ $expected;
    }

    return 1;
}

sub run {
    my $self = shift;

    $self->print_usage if $self->has_arg('h');

    my $records   = $self->get_collection_object();
    my $search_cb = $self->get_search_callback();
    $records->matching($search_cb);

    $self->display_terminal($records);
}


sub display_terminal {
    my $self    = shift;
    my $records = shift;

    my $groups = $self->group_routine->( [ $records->items ] );

    foreach my $group ( @{$groups} ) {
        $self->out_group_heading( $group, $groups );
        $self->out_record($_) for $self->sort_routine->( $group->{records} );
    }

}


sub sort_by_prop {
    my ( $self, $prop, $records, $sort_undef_last ) = @_;

    no warnings 'uninitialized';    # some records might not have this prop

    return (
        sort {
            my $prop_a = $a->prop($prop);
            my $prop_b = $b->prop($prop);
            if ( $sort_undef_last && !defined($prop_a) ) {
                return 1;
            } elsif ( $sort_undef_last && !defined($prop_b) ) {
                return -1;
            } else {
                return $prop_a cmp $prop_b;
            }
        } @{$records}
    );
}


sub group_by_prop {
    my $self    = shift;
    my $prop    = shift;
    my $records = shift;

    my $results = {};

    for my $record (@$records) {
        push @{ $results->{ ( $record->prop($prop) || '' ) } }, $record;
    }

    return [

        map { { label => $_, records => $results->{$_} } } keys %$results

    ];

}

sub out_group_heading {
    my $self   = shift;
    my $group  = shift;
    my $groups = shift;

    # skip headings with no records
    return unless exists $group->{records}->[0];

    return unless @$groups > 1;

    $group->{label} ||= 'none';
    print "\n"
      . $group->{label} . "\n"
      . ( "=" x length $group->{label} ) . "\n\n";

}

sub out_record {
    my $self   = shift;
    my $record = shift;
    print $record->format_summary . "\n";
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::CLI::Command::Search

=head1 VERSION

version 0.751

=head1 METHODS

=head2 display_terminal $records

Takes a collection of records, sorts it according to C<$sort_routine>, and then
prints it to standard output using L<Prophet::Record->format_summary> as the
format.

=head2 sort_by_prop $prop, $records, $sort_undef_last

Given a property name and an arrayref to a list of records, returns a list of
the records sorted by their C<created> property, in ascending order.

If $sort_undef_last is true, records which don't have a property defined are
sorted *after* all other records; otherwise, they are sorted before.

=head2 group_by_prop $prop => $records

Given a property name and an arrayref to a list of records, returns a reference
to a list of hashes of the form:

    { label => $label,
      records => \@records }

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
