#!/bin/sh

OUTFILE="$1"
rm -f "$OUTFILE"
> "$OUTFILE"

# Page specific hacks
case "$OUTFILE" in
    sudo.mdoc.sed)
	# Replace "0 minutes" with "unlimited"
	cat >>"$OUTFILE" <<-'EOF'
		/^\.Li 0$/ {
			N
			s/^\.Li 0\nminutes\.$/unlimited./
		}
	EOF

	# BSD auth
	BA_FLAG=
	if [ X"$BAMAN" != X"1" ]; then
		BA_FLAG='/^.*\n\.Op Fl a Ar auth_type/{;N;/^.*\n\.Ek$/d;};'
		cat >>"$OUTFILE" <<-'EOF'
			/^\.It Fl a Ar type/,/BSD authentication\.$/ {
				d
			}
		EOF
	fi

	# BSD login class
	LC_FLAG=
	if [ X"$LCMAN" != X"1" ]; then
		LC_FLAG='/^.*\n\.Op Fl c Ar class/{;N;/^.*\n\.Ek$/d;};'
		cat >>"$OUTFILE" <<-'EOF'
			/^\.It Fl c Ar class/,/BSD login classes\.$/ {
				d
			}
			/^\.Xr login_cap 3 ,$/d
			/^BSD login class$/ {
				N
				/^BSD login class\n\.It$/d
			}
		EOF
	fi

	# SELinux
	SE_FLAG=
	if [ X"$SEMAN" != X"1" ]; then
		SE_FLAG='/^.*\n\.Op Fl r Ar role/{;N;/^.*\n\.Ek$/d;};/^.*\n\.Op Fl t Ar type/{;N;/^.*\n\.Ek$/d;};'
		cat >>"$OUTFILE" <<-'EOF'
			/^\.It Fl r Ar role/,/newline character\.$/ {
				d
			}
			/^\.It Fl t Ar type/,/specified role\.$/ {
				d
			}
			/^SELinux role and type$/ {
				N
				/^SELinux role and type\n\.It$/d
			}
		EOF
	fi

	# Solaris privileges
	if [ X"$PSMAN" != X"1" ]; then
		cat >>"$OUTFILE" <<-'EOF'
			/^Solaris project$/ {
				N
				N
				N
				/^Solaris project\n\.It\nSolaris privileges\n\.It$/d
			}
		EOF
	fi

	# Unsupported flags must be removed together
	if [ -n "$BA_FLAG$LC_FLAG$SE_FLAG" ]; then
		cat >>"$OUTFILE" <<-EOF
			/^\.Bk -words\$/ {
			    N
			    $BA_FLAG$LC_FLAG$SE_FLAG
			}
		EOF
	fi
	;;
    sudoers.mdoc.sed)
	# Subsections to remove (SELinux and Solaris are adjacent)
	RM_SS=
	if [ X"$PSMAN" != X"1" ]; then
	    if [ X"$SEMAN" != X"1" ]; then
		RM_SS='/^\.Ss SELinux_Spec/,/^\.Ss [^S]/{;/^\.Ss [^S][^o][^l]/!d;};'
	    else
		RM_SS='/^\.Ss Solaris_Priv_Spec/,/^\.Ss/{;/^\.Ss [^S][^o][^l]/!d;};'
	    fi
	elif [ X"$SEMAN" != X"1" ]; then
		RM_SS='/^\.Ss SELinux_Spec/,/^\.Ss/{;/^\.Ss [^S][^E][^L]/!d;};'
	fi
	if [ -n "$RM_SS" ]; then
		cat >>"$OUTFILE" <<-EOF
			$RM_SS
		EOF
	fi

	# BSD login class
	if [ X"$LCMAN" != X"1" ]; then
		cat >>"$OUTFILE" <<-'EOF'
			/^On BSD systems/,/\.$/ {
				d
			}
			/^\.It use_loginclass$/,/^\.It/ {
				/^\.It [^u][^s][^e][^_][^l]/!d
			}
		EOF
	fi

	# Solaris PrivSpec
	if [ X"$PSMAN" != X"1" ]; then
		cat >>"$OUTFILE" <<-'EOF'
			s/Solaris_Priv_Spec? //
			/^Solaris_Priv_Spec ::=/ {
				N
				d
			}
			/^\.It limitprivs$/,/^\.It/ {
				/^\.It [^l][^i][^m][^i][^t]/!d
			}
			/^\.It privs$/,/^\.It/ {
				/^\.It [^p][^r][^i][^v][^s]$/!d
			}
			/^On Solaris 10/,/^\.Pp/ {
				d
			}
		EOF
	fi

	# SELinux
	if [ X"$SEMAN" != X"1" ]; then
		cat >>"$OUTFILE" <<-'EOF'
			s/SELinux_Spec? //
			/^SELinux_Spec ::=/ {
				N
				d
			}
			/^\.It [rt][oy][lp]e$/,/^\.It/ {
				/^\.It [^rt][^oy][^lp][^e]$/!d
			}
		EOF
	fi
	;;
esac
