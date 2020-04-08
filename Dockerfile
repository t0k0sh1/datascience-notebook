ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Takashi Yamashina <takashi.yamashina@gmail.com>"

# Set when building on Travis so that certain long-running build steps can
# be skipped to shorten build time.
ARG TEST_ONLY_BUILD

USER root

# ffmpeg for matplotlib anim & dvipng for latex labels
RUN apt-get update && \
  apt-get install -y --no-install-recommends ffmpeg dvipng && \
  rm -rf /var/lib/apt/lists/*

USER $NB_UID

# Install Python 3 packages
RUN conda install --quiet --yes \
  'beautifulsoup4=4.8.*' \
  'conda-forge::blas=*=openblas' \
  'bokeh=1.4.*' \
  'cloudpickle=1.3.*' \
  'cython=0.29.*' \
  'dask=2.11.*' \
  'dill=0.3.*' \
  'h5py=2.10.*' \
  'hdf5=1.10.*' \
  'ipywidgets=7.5.*' \
  'ipympl=0.5.*'\
  'matplotlib-base=3.2.*' \
  'numba=0.48.*' \
  'numexpr=2.7.*' \
  'pandas=1.0.*' \
  'patsy=0.5.*' \
  'protobuf=3.11.*' \
  'scikit-image=0.16.*' \
  'scikit-learn=0.22.*' \
  'scipy=1.4.*' \
  'seaborn=0.10.*' \
  'sqlalchemy=1.3.*' \
  'statsmodels=0.11.*' \
  'sympy=1.5.*' \
  'vincent=0.4.*' \
  'widgetsnbextension=3.5.*'\
  'xlrd' \
  'missingno' \
  'pandas-profiling' \
  && \
  conda clean --all -f -y && \
  # Activate ipywidgets extension in the environment that runs the notebook server
  jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
  # Also activate ipywidgets extension for JupyterLab
  # Check this URL for most recent compatibilities
  # https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
  jupyter labextension install @jupyter-widgets/jupyterlab-manager@^2.0.0 --no-build && \
  jupyter labextension install @bokeh/jupyter_bokeh@^2.0.0 --no-build && \
  jupyter labextension install jupyter-matplotlib@^0.7.2 --no-build && \
  jupyter labextension install @lckr/jupyterlab_variableinspector && \
  jupyter lab build && \
  jupyter lab clean && \
  npm cache clean --force && \
  rm -rf /home/$NB_USER/.cache/yarn && \
  rm -rf /home/$NB_USER/.node-gyp && \
  fix-permissions $CONDA_DIR && \
  fix-permissions /home/$NB_USER

# Install facets which does not have a pip or conda package at the moment
RUN cd /tmp && \
  git clone https://github.com/PAIR-code/facets.git && \
  cd facets && \
  jupyter nbextension install facets-dist/ --sys-prefix && \
  cd && \
  rm -rf /tmp/facets && \
  fix-permissions $CONDA_DIR && \
  fix-permissions /home/$NB_USER

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
  fix-permissions /home/$NB_USER

USER $NB_UID