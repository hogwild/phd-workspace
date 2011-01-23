function db = dbfrompascal2010 (vocroot, varargin)
% DBFROMPASCAL2010  Construct DB from PASCAL VOC 2010 data

% AUTORIGHTS
% Copyright (c) 2009 Brian Fulkerson and Andrea Vedaldi
% Blocks is distributed under the terms of the modified BSD license.
% The full license may be found in LICENSE.

verbose    = 0 ;
cat_filt   = '.*' ;
challenge  = 'Segmentation'; % could also be Main or Layout
which_train = 'train' ;
which_test  = 'val' ;

for i=1:2:length(varargin)
  opt = varargin{i} ;
  arg = varargin{i+1} ;
  switch lower(opt)    
    case 'verbose'
      verbose = arg ; 
    case 'challenge'
      challenge = arg ;   
    case 'catfilter'
      cat_filt = arg ;
    case 'train'
      which_train = arg;
    case 'test'
      which_test = arg;
    otherwise
      error(sprintf('Unknown option ''%s''.',opt)) ;
  end
end

if ~strcmp(challenge, 'Segmentation')
    error('dbfrompascal2010 does not know how to handle any other challenges\n');
end

verbose   = 1 ;
lastdir   = cd ;
voccode   = fullfile(vocroot,'VOCcode2010') ;

if ~ exist(voccode, 'dir')
  error(sprintf('Could not find PASCAL VOC 2010 code in ''%s''', voccode)) ;
end

if verbose
  fprintf('dbfrompascal2010: which train : ''%s''\n', which_train) ;
  fprintf('dbfrompascal2010: which test  : ''%s''\n', which_test) ;
  fprintf('dbfrompascal2010: cat filter  : ''%s''\n', cat_filt) ;
  fprintf('dbfrompascal2010: challenge   : ''%s''\n', challenge);
end

addpath(voccode) ;
cd(vocroot)

db.TRAIN      = 0 ;
db.TEST       = 1 ;
db.VALIDATION = 2 ;
db.depth      = 1 ;

try
    % initialize VOC 
    VOCinit ;

    % get categories
    db.VOCopts = VOCopts;
    db.VOCopts.testset = which_test;
    db.VOCcolors = VOClabelcolormap(256);
    
    db.images_path = fileparts(VOCopts.imgpath);
    cat_names = [VOCopts.classes] ;
    cat_ids   = 1:length(cat_names);
    % add a background category
    cat_names{length(cat_names)+1} = 'background';
    cat_ids   = [cat_ids 0];

    ncats = length(cat_names) ;

    % scan all
    db.cat_names = {} ;

    cn = 1 ;
    for c = 1:ncats
        cat_name = cat_names{c} ;
        if(isempty(regexp(cat_name, cat_filt))), continue ; end 
        db.cat_names{cn}   = cat_name ;
        db.cat_ids{cn}     = cat_ids(c);
        cn = cn + 1;
    end

    ncats = length(db.cat_names);    

    a = 1;
    train_ids = textread(sprintf(VOCopts.seg.imgsetpath, which_train), '%s');
    test_ids  = textread(sprintf(VOCopts.seg.imgsetpath, which_test) , '%s');
    sets = {train_ids, test_ids};
    flags = {db.TRAIN, db.TEST};
    for s = 1:length(sets)
        ids = sets{s};
        flag = flags{s};

        for i = 1:length(ids)
            db.aspects(a).path = [ids{i} '.jpg'];
            db.aspects(a).classseg = sprintf(VOCopts.seg.clsimgpath, ids{i});
            db.aspects(a).objseg   = sprintf(VOCopts.seg.instimgpath, ids{i});
            db.aspects(a).id       = ids{i};
            db.aspects(a).flag     = flag;
            db.aspects(a).cat      = 0;
            db.aspects(a).obj_ids  = [];

            if exist(db.aspects(a).classseg)
              rec = PASreadrecord(sprintf(VOCopts.annopath, ids{i}));
              classes = {rec.objects.class};
              cids = ncats;
              for c = 1:length(db.cat_names)
                if find(strcmp(classes, db.cat_names{c}))
                  cids = [cids c];
                end
              end
              db.aspects(a).obj_ids  = cids;
            end

            a = a + 1;
        end
    end

catch
    cd(lastdir) ;
    rmpath(voccode) ;
    error(lasterr) ;
end

cd(lastdir) ;
rmpath(voccode) ;

if verbose
    fprintf('dbfrompascal2010: done.\n') ;
    fprintf('dbfrompascal2010: %d aspects.\n',    length(db.aspects)) ;
    fprintf('dbfrompascal2010: %d categories.\n', length(db.cat_names)) ;
end
