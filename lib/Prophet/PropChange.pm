package Prophet::PropChange;
{
  $Prophet::PropChange::VERSION = '0.751';
}

# ABSTRACT: A single property change.

use Any::Moose;


has name => (
    is  => 'rw',
    isa => 'Str',
);


has old_value => (
    is  => 'rw',
    isa => 'Str|Undef',
);


has new_value => (
    is  => 'rw',
    isa => 'Str|Undef',
);

sub summary {
    my $self = shift;
    my $name = $self->name || '(property name missing)';
    my $old  = $self->old_value;
    my $new  = $self->new_value;

    if ( !defined($old) ) {
        return qq{+ "$name" set to "} . ( $new || '' ) . qq{"};
    } elsif ( !defined($new) ) {
        return qq{- "$name" "$old" deleted.};
    }

    return qq{> "$name" changed from "$old" to "$new".};
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::PropChange - A single property change.

=head1 VERSION

version 0.751

=head1 DESCRIPTION

This class encapsulates a single property change.

=head1 ATTRIBUTES

=head2 name

The name of the property we're talking about.

=head2 old_value

What L</name> changed I<from>.

=head2 new_value

What L</name> changed I<to>.

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
