FROM ruby:2.5

RUN bundle config --global frozen 1

WORKDIR /usr/src/app

RUN apt-get update

# Needed for ExecJS
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs

# Libre libreoffice
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:libreoffice/ppa
RUN apt-get install -y --no-install-recommends libreoffice-writer

RUN soffice --version

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["bundle", "exec", "puma", "-C", "puma.rb"]
